import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'app_state.dart';
import 'api_service.dart';
import 'feedback_sheet.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MoodUpliftApp());
}

// ─── Palette ──────────────────────────────────────────────────────────────────
const Color kViolet = Color(0xFFA78BFA); // rgba(167,139,250)
const Color kIndigo = Color(0xFF6366F1); // rgba(99,102,241)
const Color kPink = Color(0xFFF472B6); // rgba(244,114,182)
const Color kOrange = Color(0xFFFB923C); // rgba(251,146,60)
const Color kPurple = Color(0xFFC4B5FD); // rgba(196,181,253)

double _lerp(double a, double b, double t) => a + (b - a) * t;

class MoodUpliftApp extends StatelessWidget {
  const MoodUpliftApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoodUplift',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: const Color(0xFF000000)),
      home: const PlayerScreen(),
    );
  }
}

// ─── Track model ──────────────────────────────────────────────────────────────
class Track {
  final String title, artist, emoji;
  const Track({required this.title, required this.artist, required this.emoji});
}

// ─── Player Screen ────────────────────────────────────────────────────────────
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  // ── entrance fades
  late final AnimationController _topBarCtrl;
  late final AnimationController _moodCtrl;
  late final AnimationController _albumCtrl;
  late final AnimationController _songInfoCtrl;
  late final AnimationController _progressCtrl;
  late final AnimationController _controlsCtrl;
  late final AnimationController _upNextCtrl;

  // ── state
  int _trackIdx = 0;
  // album bounce
  double _albumOffsetX = 0;
  double _albumOpacity = 1;

  // ── sheet

  // ── YouTube playback
  YoutubePlayerController? _ytController;
  bool _ytLoading = false;
  String? _lastPromptedVideoId;

  // PERF: using ValueNotifiers to avoid full-screen rebuilds
  final ValueNotifier<bool> _playingNotifier = ValueNotifier(true);
  final ValueNotifier<double> _progressNotifier = ValueNotifier(0.0);
  final ValueNotifier<Duration> _positionNotifier =
      ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> _durationNotifier =
      ValueNotifier(const Duration(seconds: 1));

  // PERF: Drag state to prevent seek spamming
  bool _isDragging = false;

  // PERF: Throttle YouTube listener updates (~15 fps)
  int _lastUpdateTime = 0;

  late AppState _appState;
  int _localPlaylistVersion = -1;

  // Returns the current track from AppState (falls back to a dummy if empty)
  Track get _track {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.songs.isEmpty) {
      return const Track(
          title: 'No songs loaded', artist: 'Start a session', emoji: '🎵');
    }
    final song = appState.songs[_trackIdx.clamp(0, appState.songs.length - 1)];
    return Track(title: song.title, artist: song.artist, emoji: song.emoji);
  }

  String _fmtDuration(Duration d) {
    final s = d.inSeconds;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  void _after(int ms, VoidCallback fn) =>
      Future.delayed(Duration(milliseconds: ms), () {
        if (mounted) fn();
      });

  // ── Load YouTube video for current track
  Future<void> _loadYouTube() async {
    if (!mounted) return;
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.songs.isEmpty) return;

    final idx = _trackIdx.clamp(0, appState.songs.length - 1);
    final song = appState.songs[idx];
    final query = song.youtubeSearchQuery;
    if (query.isEmpty) return;

    setState(() => _ytLoading = true);
    debugPrint('MoodUplift: Fetching video for "$query"');

    try {
      final videoId = await ApiService.getYouTubeVideoId(query);

      if (!mounted) return;

      if (videoId == null) {
        debugPrint('MoodUplift: Failed to get video ID for "$query"');
        setState(() => _ytLoading = false);
        return;
      }

      debugPrint('MoodUplift: Video ID fetched: $videoId');

      // If controller already exists, simply load the new video
      if (_ytController != null) {
        _ytController!.load(videoId);
        _ytController!.play();
      } else {
        final ctrl = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            disableDragSeek: false,
            loop: false,
            isLive: false,
            enableCaption: false,
            hideControls: true,
            controlsVisibleAtStart: false,
          ),
        );
        ctrl.addListener(_onYtUpdate);
        _ytController = ctrl;
      }

      // Store videoId in AppState for quick re-entry
      appState.setCurrentVideoId(videoId);
      setState(() => _ytLoading = false);
      _playingNotifier.value = true;
    } catch (e) {
      debugPrint('MoodUplift: Error in _loadYouTube: $e');
      if (mounted) setState(() => _ytLoading = false);
    }
  }

  void _onYtUpdate() {
    if (!mounted || _ytController == null) return;

    final state = _ytController!.value.playerState;
    // Auto-prompt feedback when song finishes
    if (state == PlayerState.ended) {
      _ytController!.pause();
      final currentVideoId = _ytController!.metadata.videoId;
      if (_lastPromptedVideoId != currentVideoId) {
        _lastPromptedVideoId = currentVideoId;
        // Record the song as fully played ONLY once per end event
        _appState.incrementSongsPlayed();
        // Only show feedback sheet if feature is enabled
        if (_appState.featureFeedbackSheet) {
          showGlobalFeedback();
        } else {
          // Auto advance to next track if feedback is disabled
          _after(300, () => _changeTrack(1));
        }
      }
      return;
    }

    // PERF: Throttle updates to ~15fps (every 66ms) to prevent UI thread saturation
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastUpdateTime < 66) return;
    _lastUpdateTime = now;

    final pos = _ytController!.value.position;
    final dur = _ytController!.metadata.duration;
    final isPlaying = _ytController!.value.isPlaying;

    if (dur.inSeconds > 0) {
      final progress = pos.inMilliseconds / dur.inMilliseconds;

      // PERF: Update ValueNotifiers locally if not dragging
      if (!_isDragging) {
        _positionNotifier.value = pos;
        _durationNotifier.value = dur;
        _progressNotifier.value = progress;
      }
      _playingNotifier.value = isPlaying;

      // Push to AppState so mini players can track (PERF: using cached reference)
      _appState.updatePlayback(
        progress: progress,
        position: pos,
        duration: dur,
        playing: isPlaying,
      );
    }
  }

  @override
  void initState() {
    super.initState();

    // Restore track index from AppState for re-entry
    _appState = Provider.of<AppState>(context, listen: false);
    _localPlaylistVersion = _appState.playlistVersion;
    _appState.addListener(_onAppStateChanged);

    _trackIdx = _appState.currentTrackIndex;
    _progressNotifier.value = _appState.playbackProgress;
    _positionNotifier.value = _appState.playbackPosition;
    _durationNotifier.value = _appState.playbackDuration;
    _playingNotifier.value = _appState.isPlaying;

    // entrance
    _topBarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _moodCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _albumCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _songInfoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _controlsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _upNextCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _after(120, _moodCtrl.forward);
    _after(200, _albumCtrl.forward);
    _after(320, _songInfoCtrl.forward);
    _after(380, _progressCtrl.forward);
    _after(440, _controlsCtrl.forward);
    _after(560, _upNextCtrl.forward);

    // Load YouTube for current track
    _after(800, _loadYouTube);
  }

  void _changeTrack(int dir) {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.songs.isEmpty) return;
    final trackCount = appState.songs.length;
    HapticFeedback.selectionClick();

    setState(() {
      _albumOpacity = 0;
      _albumOffsetX = dir * 30.0;
    });

    _after(220, () {
      int nextTry = _trackIdx;
      bool found = false;

      // Try to find a non-blocked song in the given direction
      for (int i = 0; i < trackCount; i++) {
        nextTry = (nextTry + dir + trackCount) % trackCount;
        final s = appState.songs[nextTry];
        final isBlocked = appState.blockedSongs
            .any((b) => b.title == s.title && b.artist == s.artist);
        if (!isBlocked) {
          found = true;
          break;
        }
      }

      if (!found) {
        // If everything is blocked, just stay put but reset animations
        setState(() {
          _albumOpacity = 1;
          _albumOffsetX = 0;
        });
        return;
      }

      setState(() {
        _trackIdx = nextTry;
        _albumOffsetX = -dir * 30.0;
        _ytController?.removeListener(_onYtUpdate);
        _ytController?.dispose();
        _ytController = null;
      });
      _progressNotifier.value = 0;
      _positionNotifier.value = Duration.zero;
      appState.setTrackIndex(nextTry);
      _after(
        30,
        () => setState(() {
          _albumOpacity = 1;
          _albumOffsetX = 0;
        }),
      );
      _loadYouTube();
    });
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    _ytController?.removeListener(_onYtUpdate);
    _ytController?.dispose();

    _positionNotifier.dispose();
    _durationNotifier.dispose();
    _progressNotifier.dispose();
    _playingNotifier.dispose();

    _topBarCtrl.dispose();
    _moodCtrl.dispose();
    _albumCtrl.dispose();
    _songInfoCtrl.dispose();
    _progressCtrl.dispose();
    _controlsCtrl.dispose();
    _upNextCtrl.dispose();
    super.dispose();
  }

  void _onAppStateChanged() {
    if (!mounted) return;
    if (_appState.songs.isEmpty) return;

    // Check if the overall playlist was replaced (via API)
    if (_localPlaylistVersion != _appState.playlistVersion) {
      _localPlaylistVersion = _appState.playlistVersion;
      setState(() {
        _trackIdx = _appState.currentTrackIndex;
      });
      _loadYouTube();
    }
    // Otherwise check if a mini-player (from another screen) changed the track
    else if (_trackIdx != _appState.currentTrackIndex) {
      setState(() {
        _trackIdx = _appState.currentTrackIndex;
      });
      _loadYouTube();
    }
    // Check if a mini-player changed the play/pause state
    else if (_playingNotifier.value != _appState.isPlaying) {
      _playingNotifier.value = _appState.isPlaying;
      if (_playingNotifier.value) {
        _ytController?.play();
      } else {
        _ytController?.pause();
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: LayoutBuilder(
        builder: (context, cs) {
          final W = cs.maxWidth;
          final H = cs.maxHeight;
          return Stack(
            children: [
              // Load YouTube player for audio only (hidden at the very back).
              // Must be > 1x1 to prevent Gralloc memory crashes on some Android devices.
              if (_ytController != null)
                Positioned(
                  left: -100, // Move off-screen but keep active
                  top: -100,
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: YoutubePlayer(
                      controller: _ytController!,
                      showVideoProgressIndicator: false,
                    ),
                  ),
                ),
              _background(W, H),
              _mainContent(W, H),
            ],
          );
        },
      ),
    );
  }

  // ─── Background ──────────────────────────────────────────────────────────────
  Widget _background(double W, double H) {
    return const Positioned.fill(
      child: ColoredBox(color: Color(0xFF000000)),
    );
  }

  // ─── Main content ─────────────────────────────────────────────────────────────
  Widget _mainContent(double W, double H) {
    return Positioned.fill(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(W * 0.062, 0, W * 0.062, 20),
          child: Column(
            children: [
              SizedBox(height: H * 0.008),
              _fadeUp(_topBarCtrl, _topBar()),
              SizedBox(height: H * 0.016),
              _fadeUp(_moodCtrl, _moodIndicator(W)),
              SizedBox(height: H * 0.016),
              _fadeUp(_albumCtrl, _albumWrap(W, H), scale: true),
              SizedBox(height: H * 0.022),
              _fadeUp(_songInfoCtrl, _songInfo()),
              SizedBox(height: H * 0.006),
              _fadeUp(_progressCtrl, _progressSection()),
              SizedBox(height: H * 0.016),
              _fadeUp(_controlsCtrl, _controls()),
              SizedBox(height: H * 0.012),
              // Up Next card
              _fadeUp(_upNextCtrl, _upNextCard()),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Top bar ─────────────────────────────────────────────────────────────────
  Widget _topBar() {
    return Row(
      children: [
        _iconBtn('‹',
            onTap: () =>
                Provider.of<AppState>(context, listen: false).closePlayer()),
        const Spacer(),
        Text(
          'NOW PLAYING',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.45),
            letterSpacing: 0.14 * 13,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 36),
      ],
    );
  }

  Widget _iconBtn(String icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 44, sigmaY: 44),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.18),
                  offset: const Offset(0, 1),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.15),
                  offset: const Offset(0, -1),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 18,
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x2EFFFFFF), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    icon,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Mood indicator ───────────────────────────────────────────────────────────
  Widget _moodIndicator(double W) {
    return Row(
      children: [
        // pill
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: kViolet.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kViolet.withValues(alpha: 0.30)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: 0.8,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kViolet,
                        boxShadow: [
                          BoxShadow(
                            color: kViolet.withValues(alpha: 0.8),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Consumer<AppState>(
                    builder: (_, s, __) => Text(
                      s.currentMood.isNotEmpty
                          ? s.currentMood.toUpperCase()
                          : 'SAD',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kViolet.withValues(alpha: 0.9),
                        letterSpacing: 0.10 * 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Album art ────────────────────────────────────────────────────────────────
  Widget _albumWrap(double W, double H) {
    final artSize = W * 0.585;
    return SizedBox(
      width: W,
      height: artSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // glow
          Opacity(
            opacity: 0.9,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 42, sigmaY: 42),
              child: Container(
                width: W * 0.666,
                height: W * 0.666,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      kViolet.withValues(alpha: 0.45),
                      kPink.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.45, 0.70],
                  ),
                ),
              ),
            ),
          ),
          // album art
          AnimatedOpacity(
            opacity: _albumOpacity,
            duration: const Duration(milliseconds: 350),
            curve: const Cubic(0.22, 1, 0.36, 1),
            child: AnimatedSlide(
              offset: Offset(_albumOffsetX / artSize, 0),
              duration: const Duration(milliseconds: 350),
              curve: const Cubic(0.22, 1, 0.36, 1),
              child: Container(
                width: artSize,
                height: artSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.55),
                      blurRadius: 60,
                      offset: const Offset(0, 20),
                    ),
                    BoxShadow(
                        color: kViolet.withValues(alpha: 0.22), blurRadius: 40),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.12),
                      offset: const Offset(0, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(27),
                  child: Stack(
                    children: [
                      // background gradient (always shown behind)
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF2D1F52),
                              Color(0xFF1A1035),
                              Color(0xFF231840),
                              Color(0xFF1C1235),
                            ],
                            stops: [0, 0.4, 0.7, 1],
                          ),
                        ),
                      ),
                      // Always show original art
                      ...[
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(-0.4, -0.4),
                                colors: [
                                  kViolet.withValues(alpha: 0.60),
                                  Colors.transparent,
                                ],
                                radius: 0.8,
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(0.5, 0.3),
                                colors: [
                                  kPink.withValues(alpha: 0.55),
                                  Colors.transparent,
                                ],
                                radius: 0.8,
                              ),
                            ),
                          ),
                        ),
                        // static inner
                        Center(
                          child: Text(
                            _track.emoji,
                            style: const TextStyle(fontSize: 72),
                          ),
                        ),
                      ],
                      // Loading spinner overlay
                      if (_ytLoading)
                        Positioned.fill(
                          child: Container(
                            color:
                                const Color(0xFF000000).withValues(alpha: 0.5),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: kViolet.withValues(alpha: 0.8),
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Song info ────────────────────────────────────────────────────────────────
  Widget _songInfo() {
    final appState = Provider.of<AppState>(context, listen: false);
    final songResult =
        appState.songs[_trackIdx.clamp(0, appState.songs.length - 1)];
    final isLiked = appState.isLiked(songResult);
    final isBlocked = appState.blockedSongs.any(
        (b) => b.title == songResult.title && b.artist == songResult.artist);

    return Row(
      children: [
        // icon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
          ),
          child: Center(
            child: Text(
              _track.emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        const SizedBox(width: 14),
        // text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFF5F0FF),
                  height: 1.15,
                  letterSpacing: -0.26,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _track.artist,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.50),
                  letterSpacing: 0.26,
                ),
              ),
            ],
          ),
        ),
        // like btn
        _heartBtn(
          emoji: isLiked ? '💜' : '🤍',
          active: isLiked,
          onTap: () => setState(() {
            appState.toggleLike(songResult);
          }),
        ),
        const SizedBox(width: 8),
        // block btn — only shown if song blocking feature is enabled
        if (context.read<AppState>().featureSongBlocking)
        _heartBtn(
          emoji: '🚫',
          active: isBlocked,
          activeColor: const Color(0xFFEF4444),
          onTap: () {
            setState(() {
              appState.blockSong(songResult);
            });
            if (!isBlocked) _after(500, () => _changeTrack(1));
          },
        ),
      ],
    );
  }

  Widget _heartBtn({
    required String emoji,
    required bool active,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: active ? 1.0 : 1.0,
        duration: const Duration(milliseconds: 250),
        child: ClipOval(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? (activeColor ?? kPink).withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.07),
                border: Border.all(
                  color: active
                      ? (activeColor ?? kPink).withValues(alpha: 0.50)
                      : Colors.white.withValues(alpha: 0.14),
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: (activeColor ?? kPink).withValues(alpha: 0.20),
                          blurRadius: 16,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Progress ─────────────────────────────────────────────────────────────────
  Widget _progressSection() {
    return Column(
      children: [
        GestureDetector(
          onTapDown: (d) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            // approximate — full width seek
          },
          child: LayoutBuilder(
            builder: (ctx, cs) {
              return GestureDetector(
                onTapDown: (d) {
                  final p = (d.localPosition.dx / cs.maxWidth).clamp(0.0, 1.0);
                  _progressNotifier.value = p;
                  final pos = Duration(
                      milliseconds:
                          (_durationNotifier.value.inMilliseconds * p).toInt());
                  _ytController?.seekTo(pos);
                },
                onHorizontalDragStart: (_) => _isDragging = true,
                onHorizontalDragUpdate: (d) {
                  final p = (d.localPosition.dx / cs.maxWidth).clamp(0.0, 1.0);
                  _progressNotifier.value = p;
                  // PERF: do not seekTo repeatedly during drag, only update visual notifier
                },
                onHorizontalDragEnd: (d) {
                  _isDragging = false;
                  final pos = Duration(
                      milliseconds: (_durationNotifier.value.inMilliseconds *
                              _progressNotifier.value)
                          .toInt());
                  _ytController?.seekTo(pos);
                },
                onHorizontalDragCancel: () => _isDragging = false,
                child: SizedBox(
                  height: 20,
                  child: ValueListenableBuilder<double>(
                      valueListenable: _progressNotifier,
                      builder: (context, progress, _) {
                        return Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            // track
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            // fill
                            FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: const LinearGradient(
                                    colors: [kViolet, kPink],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kViolet.withValues(alpha: 0.60),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // thumb
                            Positioned(
                              left: progress *
                                      (MediaQuery.of(context).size.width - 48) -
                                  7,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: kViolet.withValues(alpha: 0.70),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kViolet.withValues(alpha: 0.80),
                                      blurRadius: 10,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF000000)
                                          .withValues(alpha: 0.40),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ValueListenableBuilder<Duration>(
                valueListenable: _positionNotifier,
                builder: (context, position, _) {
                  return Text(
                    _fmtDuration(position),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.38),
                    ),
                  );
                }),
            ValueListenableBuilder<Duration>(
                valueListenable: _durationNotifier,
                builder: (context, duration, _) {
                  return Text(
                    _fmtDuration(duration),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.38),
                    ),
                  );
                }),
          ],
        ),
      ],
    );
  }

  // ─── Controls ────────────────────────────────────────────────────────────────
  void _togglePlay() {
    _playingNotifier.value = !_playingNotifier.value;
    if (_ytController != null) {
      if (_playingNotifier.value) {
        _ytController!.play();
      } else {
        _ytController!.pause();
      }
    }
  }

  Widget _controls() {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final showSkip = appState.featureSkipSong;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showSkip)
              _ctrlBtn(Icons.skip_previous_rounded, onTap: () => _changeTrack(-1)),
            if (showSkip) const SizedBox(width: 32),
            _playPauseBtn(),
            if (showSkip) const SizedBox(width: 32),
            if (showSkip)
              _ctrlBtn(Icons.skip_next_rounded, onTap: () => _changeTrack(1)),
          ],
        );
      },
    );
  }

  Widget _ctrlBtn(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.14),
                  offset: const Offset(0, 1),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 22,
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x24FFFFFF), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    icon,
                    size: 28,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _playPauseBtn() {
    return GestureDetector(
      onTap: _togglePlay,
      child: ValueListenableBuilder<bool>(
        valueListenable: _playingNotifier,
        builder: (context, playing, _) {
          final glow = playing ? 0.60 : 0.30;
          final outer = playing ? 0.35 : 0.10;
          return Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xF2A78BFA), Color(0xE68B5CF6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.18),
                  offset: const Offset(0, 1),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.22),
                  offset: const Offset(0, -2),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: glow),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                    color: kViolet.withValues(alpha: outer), blurRadius: 60),
              ],
            ),
            child: ClipOval(
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 36,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x47FFFFFF), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 34,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Up Next card ────────────────────────────────────────────────────────────
  Widget _upNextCard() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.songs.isEmpty) return const SizedBox.shrink();
    final nextIdx = (_trackIdx + 1) % appState.songs.length;
    final nextSong = appState.songs[nextIdx];
    final next = Track(
      title: nextSong.title,
      artist: nextSong.artist,
      emoji: nextSong.emoji,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.07),
                offset: const Offset(0, 2),
                blurRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.18),
                offset: const Offset(0, -1),
                blurRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 24,
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x0FFFFFFF), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UP NEXT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.16 * 10,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // thumb
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2A1830), Color(0xFF1D1528)],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            next.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              next.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.85),
                                letterSpacing: 0.13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              next.artist,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.42),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '4:52',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────
  Widget _fadeUp(AnimationController ctrl, Widget child, {bool scale = false}) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final v = CurvedAnimation(
          parent: ctrl,
          curve: const Cubic(0.22, 1, 0.36, 1),
        ).value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, _lerp(14, 0, v)),
            child: scale
                ? Transform.scale(scale: _lerp(0.88, 1.0, v), child: child)
                : child,
          ),
        );
      },
    );
  }
}
