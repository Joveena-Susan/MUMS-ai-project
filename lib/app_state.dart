import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

// ─── Data models ─────────────────────────────────────────────────────────────

class SongResult {
  final String title;
  final String artist;
  final String youtubeSearchQuery;
  final String emoji;
  final String? playedInMood;

  const SongResult({
    required this.title,
    required this.artist,
    required this.youtubeSearchQuery,
    this.emoji = '🎵',
    this.playedInMood,
  });

  factory SongResult.fromJson(Map<String, dynamic> j) => SongResult(
        title: j['title'] as String? ?? '',
        artist: j['artist'] as String? ?? '',
        youtubeSearchQuery: j['youtube_search_query'] as String? ?? '',
        playedInMood: j['played_in_mood'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'artist': artist,
        'youtube_search_query': youtubeSearchQuery,
        'played_in_mood': playedInMood,
      };
}

class BlockedSong {
  final String title;
  final String artist;
  const BlockedSong({required this.title, required this.artist});

  Map<String, dynamic> toJson() => {'title': title, 'artist': artist};
  factory BlockedSong.fromJson(Map<String, dynamic> j) =>
      BlockedSong(title: j['title'] as String, artist: j['artist'] as String);
}

class MoodTransition {
  final String from;
  final String to;
  final String fromEmoji;
  final String toEmoji;
  final String time;
  final int intensity;

  const MoodTransition({
    required this.from,
    required this.to,
    required this.fromEmoji,
    required this.toEmoji,
    required this.time,
    required this.intensity,
  });

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'from_emoji': fromEmoji,
        'to_emoji': toEmoji,
        'time': time,
        'intensity': intensity,
      };

  factory MoodTransition.fromJson(Map<String, dynamic> j) {
    final f = j['from'] as String? ?? '';
    final t = j['to'] as String? ?? '';
    return MoodTransition(
      from: f,
      to: t,
      fromEmoji: j['from_emoji'] as String? ?? AppState.moodEmoji(f),
      toEmoji: j['to_emoji'] as String? ?? AppState.moodEmoji(t),
      time: j['time'] as String? ?? '',
      intensity: j['intensity'] as int? ?? 50,
    );
  }
}

class SessionRecord {
  final String date;
  final String startMood;
  final String targetMood;
  final String endMood;
  final int moodIntensity; // This will store the average
  final List<SongResult> songsPlayed;
  final String durationMinutes;
  final bool isLive;
  final List<MoodTransition> transitions;
  final List<int> intensities;

  const SessionRecord({
    required this.date,
    required this.startMood,
    required this.targetMood,
    required this.endMood,
    required this.moodIntensity,
    required this.songsPlayed,
    required this.durationMinutes,
    this.isLive = false,
    this.transitions = const [],
    this.intensities = const [],
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'start_mood': startMood,
        'target_mood': targetMood,
        'end_mood': endMood,
        'intensity': moodIntensity,
        'songs': songsPlayed.map((s) => s.toJson()).toList(),
        'duration': durationMinutes,
        'transitions': transitions.map((t) => t.toJson()).toList(),
        'intensities': intensities,
      };

  factory SessionRecord.fromJson(Map<String, dynamic> j) => SessionRecord(
        date: j['date'] as String? ?? '—',
        startMood: j['start_mood'] as String? ?? '—',
        targetMood: j['target_mood'] as String? ?? '—',
        endMood: j['end_mood'] as String? ?? '—',
        moodIntensity: j['intensity'] as int? ?? 50,
        songsPlayed: (j['songs'] as List<dynamic>? ?? [])
            .map((e) => SongResult.fromJson(e as Map<String, dynamic>))
            .toList(),
        durationMinutes: j['duration'] as String? ?? '—',
        transitions: (j['transitions'] as List<dynamic>? ?? [])
            .map((e) => MoodTransition.fromJson(e as Map<String, dynamic>))
            .toList(),
        intensities: (j['intensities'] as List<dynamic>? ?? []).cast<int>(),
      );
}

// ─── AppState ─────────────────────────────────────────────────────────────────

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  Timer? _heartbeatTimer;

  AppState() {
    WidgetsBinding.instance.addObserver(this);
  }

  // ── Auth ──
  bool _isLoggedIn = false;
  String _userName = '';
  String _userEmail = '';
  String _userPassword = '';
  String _userDOB = '';
  String _userAge = '';
  String _userGender = '';

  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPassword => _userPassword;
  String get userDOB => _userDOB;
  String get userAge => _userAge;
  String get userGender => _userGender;

  // ── Current session input ──
  String _inputText = '';
  List<String> _selectedLanguages = ['malayalam', 'hindi', 'english'];

  String get inputText => _inputText;
  List<String> get selectedLanguages => List.unmodifiable(_selectedLanguages);

  void setInputText(String t) {
    _inputText = t;
    notifyListeners();
  }

  void setLanguages(List<String> langs) {
    _selectedLanguages = List.of(langs);
    notifyListeners();
  }

  // ── AI result ──
  String _currentMood = '';
  String _targetMood = '';
  int _moodIntensity = 50;
  List<SongResult> _songs = [];
  int _playlistVersion = 0;
  DateTime _sessionStartTime = DateTime.now();
  Duration _sessionActiveDuration = Duration.zero;
  DateTime? _lastPlaybackTick;
  String _sessionStartMood = '';
  List<MoodTransition> _activeTransitions = [];
  List<SongResult> _sessionSongsPlayed = [];
  List<int> _sessionIntensities = []; // NEW: Intensity history for average

  String get currentMood => _currentMood;
  String get targetMood => _targetMood;
  int get moodIntensity => _moodIntensity;
  List<SongResult> get songs => List.unmodifiable(_songs);
  int get playlistVersion => _playlistVersion;
  DateTime get sessionStartTime => _sessionStartTime;
  Duration get sessionActiveDuration => _sessionActiveDuration;
  List<MoodTransition> get activeTransitions =>
      List.unmodifiable(_activeTransitions);
  List<SongResult> get sessionSongsPlayed =>
      List.unmodifiable(_sessionSongsPlayed);

  // ── Player state ──
  int _currentTrackIndex = 0;
  bool _isPlaying = false;
  int _sessionSkipsCount = 0; // ✅ AI data: track skips per session

  int get currentTrackIndex => _currentTrackIndex;
  bool get isPlaying => _isPlaying;

  SongResult? get currentTrack =>
      _songs.isNotEmpty ? _songs[_currentTrackIndex] : null;

  void setTrackIndex(int i) {
    _currentTrackIndex = i.clamp(0, _songs.isEmpty ? 0 : _songs.length - 1);
    notifyListeners();
  }

  void nextTrack() {
    if (_songs.isEmpty) return;
    // ✅ Log current song as skipped (unless it's blank or already finished)
    if (currentTrack != null) {
      logSongSkipped(currentTrack!);
      _sessionSkipsCount++; // ✅ AI data
    }
    _currentTrackIndex = (_currentTrackIndex + 1) % _songs.length;
    notifyListeners();
  }

  void previousTrack() {
    if (_songs.isEmpty) return;
    _currentTrackIndex =
        (_currentTrackIndex - 1 + _songs.length) % _songs.length;
    notifyListeners();
  }

  void setPlaying(bool v) {
    _isPlaying = v;
    notifyListeners();
  }

  // ── Playback tracking (shared across screens) ──
  double _playbackProgress = 0.0;
  Duration _playbackPosition = Duration.zero;
  Duration _playbackDuration = const Duration(seconds: 1);
  String? _currentVideoId;
  int _songsPlayedCount = 0;

  double get playbackProgress => _playbackProgress;
  Duration get playbackPosition => _playbackPosition;
  Duration get playbackDuration => _playbackDuration;
  String? get currentVideoId => _currentVideoId;
  int get songsPlayedCount => _songsPlayedCount;
  int get sessionSkipsCount => _sessionSkipsCount;

  void updatePlayback({
    required double progress,
    required Duration position,
    required Duration duration,
    required bool playing,
  }) {
    _playbackProgress = progress;
    _playbackPosition = position;
    _playbackDuration = duration;

    final now = DateTime.now();
    if (playing) {
      if (_lastPlaybackTick != null) {
        _sessionActiveDuration += now.difference(_lastPlaybackTick!);
      }
      _lastPlaybackTick = now;
    } else {
      _lastPlaybackTick = null;
    }

    _isPlaying = playing;
    notifyListeners();
  }

  void setCurrentVideoId(String? id) {
    _currentVideoId = id;
    notifyListeners();
  }

  static const List<String> kMoodLadder = [
    'sad',
    'calm',
    'neutral',
    'happy',
    'energised'
  ];

  int _moodLevel(String mood) {
    final m = mood.toLowerCase();
    int idx = kMoodLadder.indexOf(m);
    if (idx < 0) {
      if (m == 'joyful') return 3;
      if (m == 'energetic') return 4;
      if (m == 'energised') return 4; // Already in ladder but just in case
      if (m == 'melancholic') return 0;
      if (m == 'relaxed') return 1;
      if (m == 'hopeful') return 2;
      return 2;
    }
    return idx;
  }

  List<SongResult> _unEvaluatedSongs = [];

  void _evaluateSongs(int oldLevel, int newLevel) {
    if (_unEvaluatedSongs.isEmpty) return;

    final moodImproved = newLevel > oldLevel;

    if (moodImproved) {
      if (_isLoggedIn) {
        final songsToUnlog = _unEvaluatedSongs
            .map((s) => {
                  'title': s.title,
                  'artist': s.artist,
                })
            .toList();
        ApiService.unlogSongs(email: _userEmail, songs: songsToUnlog)
            .catchError((e) => debugPrint('unlogSongs error: $e'));

        for (var moodKey in _playedSongs.keys) {
          _playedSongs[moodKey]?.removeWhere((ps) => _unEvaluatedSongs
              .any((ss) => ss.title == ps.title && ss.artist == ps.artist));
        }
      }
    } else {
      bool addedAny = false;
      for (var s in _unEvaluatedSongs) {
        if (!_blockedSongs
            .any((b) => b.title == s.title && b.artist == s.artist)) {
          _blockedSongs.add(BlockedSong(title: s.title, artist: s.artist));
          addedAny = true;
        }
      }
      if (addedAny) {
        _saveBlockedSongs();
        if (_isLoggedIn) {
          ApiService.syncPreferences(_userEmail, _blockedSongs, _likedSongs)
              .catchError((e) => debugPrint('syncPreferences error: $e'));
        }
      }
    }

    _unEvaluatedSongs.clear();
  }

  void _finalizeLiveSession() {
    if (_songs.isEmpty) return;

    final duration = _sessionActiveDuration;
    final m = duration.inMinutes;
    final s = duration.inSeconds % 60;
    final durationStr = "${m}m ${s}s";

    final timeStr =
        "${_sessionStartTime.hour.toString().padLeft(2, '0')}:${_sessionStartTime.minute.toString().padLeft(2, '0')}";

    final avgIntensity = _sessionIntensities.isEmpty
        ? _moodIntensity
        : (_sessionIntensities.reduce((a, b) => a + b) /
                _sessionIntensities.length)
            .round();

    // ✅ AI: compute liked songs count during this session from in-memory liked list
    final likedDuringSession = _sessionSongsPlayed
        .where((s) =>
            _likedSongs.any((l) => l.title == s.title && l.artist == s.artist))
        .length;

    _history.insert(
        0,
        SessionRecord(
          date:
              '${_sessionStartTime.day}/${_sessionStartTime.month}/${_sessionStartTime.year} • $timeStr',
          startMood: _sessionStartMood,
          targetMood: _targetMood,
          endMood: _currentMood,
          moodIntensity: avgIntensity,
          songsPlayed: List.from(_sessionSongsPlayed),
          durationMinutes: durationStr,
          transitions: List.from(_activeTransitions),
          intensities: List.from(_sessionIntensities),
        ));
    _saveHistory();

    // ✅ AI: log session outcome to backend asynchronously
    if (_isLoggedIn && _sessionStartMood.isNotEmpty) {
      final startIntensity = _sessionIntensities.isNotEmpty
          ? _sessionIntensities.first
          : _moodIntensity;
      ApiService.logSessionOutcome(
        email: _userEmail,
        startMood: _sessionStartMood,
        endMood: _currentMood,
        startIntensity: startIntensity,
        endIntensity: _moodIntensity,
        songsPlayedCount: _sessionSongsPlayed.length,
        songsSkippedCount: _sessionSkipsCount,
        likedSongsCount: likedDuringSession,
        moodImproved: _moodLevel(_currentMood) > _moodLevel(_sessionStartMood),
        durationSecs: _sessionActiveDuration.inSeconds,
        sessionDate: _sessionStartTime.toIso8601String(),
      ).catchError((e) => debugPrint('logSessionOutcome error: $e'));
    }
  }

  void incrementSongsPlayed() {
    if (currentTrack != null) {
      if (!_sessionSongsPlayed.any((s) => s.title == currentTrack!.title)) {
        // Create a copy with the current mood recorded
        final recordedSong = SongResult(
          title: currentTrack!.title,
          artist: currentTrack!.artist,
          youtubeSearchQuery: currentTrack!.youtubeSearchQuery,
          emoji: currentTrack!.emoji,
          playedInMood: _currentMood,
        );
        _sessionSongsPlayed.add(recordedSong);
        _unEvaluatedSongs.add(recordedSong);
        // ✅ Log to smart song history
        logSongPlayed(currentTrack!);
      }
    }
    _songsPlayedCount++;
    notifyListeners();
  }

  void setApiResult({
    required String currentMood,
    required String targetMood,
    required int intensity,
    required List<SongResult> songs,
    bool isUpdate = false,
  }) {
    // Correcting Energised/Energetic synonyms
    if (currentMood.toLowerCase() == 'energetic') currentMood = 'Energised';
    if (targetMood.toLowerCase() == 'energetic') targetMood = 'Energised';

    // If already Energised, stay Energised and set target to same
    if (currentMood.toLowerCase() == 'energised') {
      targetMood = 'Energised';
    }

    bool didSplit = false;
    if (isUpdate && _currentMood.isNotEmpty) {
      final oldLevel = _moodLevel(_currentMood);
      final newLevel = _moodLevel(currentMood);

      if (newLevel < oldLevel) {
        // Mood declined: split session
        _evaluateSongs(oldLevel, newLevel);
        _finalizeLiveSession();
        didSplit = true;
        isUpdate = false; // Rest of logic will reset session stats as start
      } else {
        // Normal transition (improved or stayed the same)
        _evaluateSongs(oldLevel, newLevel);
        if (_currentMood != currentMood) {
          final now = DateTime.now();
          final timeStr =
              "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
          _activeTransitions.add(MoodTransition(
            from: _currentMood,
            to: currentMood,
            fromEmoji: moodEmoji(_currentMood),
            toEmoji: moodEmoji(currentMood),
            time: timeStr,
            intensity: intensity,
          ));
        }
      }
    }

    if (!isUpdate) {
      if (!didSplit && _songs.isNotEmpty) {
        // Only finalize if we actually had a journey started and not already split
        _evaluateSongs(_moodLevel(_currentMood), _moodLevel(_currentMood));
        _finalizeLiveSession();
      }

      _activeTransitions = [];
      _sessionSongsPlayed = [];
      _unEvaluatedSongs = [];
      _sessionIntensities = []; // Reset intensities
      _songsPlayedCount = 0;
      _sessionSkipsCount = 0; // ✅ AI: reset skip counter
      _sessionActiveDuration = Duration.zero;
      _sessionStartTime = DateTime.now();
      _sessionStartMood = currentMood;
    }

    _currentMood = currentMood;
    _targetMood = targetMood;
    _moodIntensity = intensity;
    _sessionIntensities.add(intensity); // Add to current session history
    _songs = List.of(songs);
    _currentTrackIndex = 0;
    _playbackProgress = 0;
    _playbackPosition = Duration.zero;
    _currentVideoId = null;
    _playlistVersion++;
    _lastPlaybackTick = null;
    notifyListeners();
  }

  // ── Global Player Overlay State ──
  bool _isPlayerOpen = false;
  bool get isPlayerOpen => _isPlayerOpen;

  void openPlayer() {
    _isPlayerOpen = true;
    notifyListeners();
  }

  void closePlayer() {
    _isPlayerOpen = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_isLoggedIn && _userEmail.isNotEmpty) {
        ApiService.sendLifecycle(_userEmail, 'online');
      } else {
        _stopHeartbeat();
      }
    });
    // Fire immediately
    if (_isLoggedIn && _userEmail.isNotEmpty) {
      ApiService.sendLifecycle(_userEmail, 'online');
    }
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    if (_isLoggedIn && _userEmail.isNotEmpty) {
      ApiService.sendLifecycle(_userEmail, 'offline');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isLoggedIn) _startHeartbeat();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _stopHeartbeat();
    }
  }

  // ── Blocked songs (disliked) ──
  List<BlockedSong> _blockedSongs = [];
  List<BlockedSong> get blockedSongs => List.unmodifiable(_blockedSongs);

  void blockSong(SongResult song) {
    if (!_blockedSongs
        .any((b) => b.title == song.title && b.artist == song.artist)) {
      _blockedSongs.add(BlockedSong(title: song.title, artist: song.artist));
    }
    _saveBlockedSongs();
    notifyListeners();
  }

  void unblockAllSongs() {
    _blockedSongs.clear();
    _saveBlockedSongs();
    notifyListeners();
  }

  // ── Liked songs ──
  List<BlockedSong> _likedSongs = [];
  List<BlockedSong> get likedSongs => List.unmodifiable(_likedSongs);

  // ── Played songs per mood (smart deduplication) ──
  // Keyed by detected mood (e.g. 'Sad', 'Happy') -> list of played/skipped songs
  Map<String, List<BlockedSong>> _playedSongs = {};

  List<BlockedSong> getPlayedSongsForMood(String mood) {
    return List.unmodifiable(_playedSongs[mood] ?? []);
  }

  // Log a song as 'played' and sync to backend
  void logSongPlayed(SongResult song) {
    if (_currentMood.isEmpty) return;
    final mood = _currentMood;
    _playedSongs.putIfAbsent(mood, () => []);
    final already = _playedSongs[mood]!
        .any((s) => s.title == song.title && s.artist == song.artist);
    if (!already) {
      _playedSongs[mood]!
          .add(BlockedSong(title: song.title, artist: song.artist));
    }
    if (_isLoggedIn) {
      ApiService.logSong(
        email: _userEmail,
        mood: mood,
        title: song.title,
        artist: song.artist,
        action: 'played',
      ).catchError((e) => debugPrint('logSong played error: $e'));
    }
  }

  // Log a song as 'skipped' and sync to backend
  void logSongSkipped(SongResult song) {
    if (_currentMood.isEmpty) return;
    final mood = _currentMood;
    _playedSongs.putIfAbsent(mood, () => []);
    final already = _playedSongs[mood]!
        .any((s) => s.title == song.title && s.artist == song.artist);
    if (!already) {
      _playedSongs[mood]!
          .add(BlockedSong(title: song.title, artist: song.artist));
    }
    if (_isLoggedIn) {
      ApiService.logSong(
        email: _userEmail,
        mood: mood,
        title: song.title,
        artist: song.artist,
        action: 'skipped',
      ).catchError((e) => debugPrint('logSong skipped error: $e'));
    }
  }

  bool isLiked(SongResult song) {
    return _likedSongs
        .any((l) => l.title == song.title && l.artist == song.artist);
  }

  void toggleLike(SongResult song) {
    final idx = _likedSongs
        .indexWhere((l) => l.title == song.title && l.artist == song.artist);
    if (idx >= 0) {
      _likedSongs.removeAt(idx);
    } else {
      _likedSongs.add(BlockedSong(title: song.title, artist: song.artist));
    }
    _saveLikedSongs();
    notifyListeners();
  }

  // ── History ──
  List<SessionRecord> _history = [];

  List<SessionRecord> get history {
    final list = List<SessionRecord>.from(_history);
    if (_songs.isNotEmpty) {
      // Create a live session record
      final now = DateTime.now();
      final duration = _sessionActiveDuration;
      final m = duration.inMinutes;
      final s = duration.inSeconds % 60;
      final durationStr = "${m}m ${s}s";
      final timeStr =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      final avgIntensity = _sessionIntensities.isEmpty
          ? _moodIntensity
          : (_sessionIntensities.reduce((a, b) => a + b) /
                  _sessionIntensities.length)
              .round();

      final liveLine = SessionRecord(
        date: '${now.day}/${now.month}/${now.year} • $timeStr',
        startMood:
            _sessionStartMood.isNotEmpty ? _sessionStartMood : _currentMood,
        targetMood: _targetMood,
        endMood: _songsPlayedCount >= _songs.length ? _targetMood : '',
        moodIntensity: avgIntensity,
        songsPlayed: _sessionSongsPlayed,
        durationMinutes: durationStr,
        isLive: true,
        transitions: _activeTransitions,
        intensities: List.from(_sessionIntensities),
      );
      list.insert(0, liveLine);
    }
    return List.unmodifiable(list);
  }

  void addSession(SessionRecord record) {
    _history.insert(0, record);
    _saveHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history.clear();
    // Reset current session
    _currentMood = '';
    _targetMood = '';
    _moodIntensity = 50;
    _songs = [];
    _playlistVersion++;
    _sessionStartMood = '';
    _activeTransitions = [];
    _sessionSongsPlayed = [];
    _unEvaluatedSongs = [];
    _sessionIntensities = [];
    _songsPlayedCount = 0;
    _sessionActiveDuration = Duration.zero;
    _lastPlaybackTick = null;
    _isPlaying = false;
    _currentVideoId = null;

    await _saveHistory();
    notifyListeners();
  }

  /// Clears ALL played/skipped song history from the backend database.
  /// This is called from the 'Clear Played History' button in Settings.
  /// Unlike logout, this action PERMANENTLY removes data from the server.
  Future<void> clearPlayedSongsHistory() async {
    _playedSongs = {}; // clear in-memory cache
    if (_isLoggedIn) {
      await ApiService.clearPlayedSongs(email: _userEmail);
    }
    notifyListeners();
  }

  // ── AI Insights ─────────────────────────────────────────────────────────────
  List<String> _aiInsights = [];
  bool _aiInsightsLoading = false;

  List<String> get aiInsights => _aiInsights;
  bool get aiInsightsLoading => _aiInsightsLoading;

  /// Fetches AI-generated emotional insights from the backend.
  /// Called when the user opens the History screen.
  Future<void> loadAiInsights() async {
    if (!_isLoggedIn || _userEmail.isEmpty) return;
    _aiInsightsLoading = true;
    notifyListeners();
    try {
      final result = await ApiService.getAiInsights(email: _userEmail);
      _aiInsights = result;
    } catch (e) {
      debugPrint('loadAiInsights error: $e');
    } finally {
      _aiInsightsLoading = false;
      notifyListeners();
    }
  }

  // ── Admin Feature Toggles & Branding ──
  bool _featureAiInsights = true;
  bool _featureSongBlocking = true;
  bool _featureFeedbackSheet = true;
  bool _featureVoiceInput = true;
  bool _featureMultilingual = true;
  bool _featureSkipSong = true;
  
  String _appName = 'MoodUplift';
  String _tagline = 'Music Therapy Companion';

  bool get featureAiInsights => _featureAiInsights;
  bool get featureSongBlocking => _featureSongBlocking;
  bool get featureFeedbackSheet => _featureFeedbackSheet;
  bool get featureVoiceInput => _featureVoiceInput;
  bool get featureMultilingual => _featureMultilingual;
  bool get featureSkipSong => _featureSkipSong;
  
  String get appName => _appName;
  String get tagline => _tagline;

  Future<void> fetchFeatureToggles() async {
    try {
      final toggles = await ApiService.getFeatureToggles();
      _featureAiInsights = toggles['ai_insights_enabled'] as bool? ?? true;
      _featureSongBlocking = toggles['song_blocking_enabled'] as bool? ?? true;
      _featureFeedbackSheet = toggles['feedback_sheet_enabled'] as bool? ?? true;
      _featureVoiceInput = toggles['voice_input_enabled'] as bool? ?? true;
      _featureMultilingual = toggles['multilingual_enabled'] as bool? ?? true;
      _featureSkipSong = toggles['skip_song_enabled'] as bool? ?? true;
      
      final branding = await ApiService.getBranding();
      if (branding.isNotEmpty) {
        _appName = branding['app_name'] as String? ?? 'MoodUplift';
        _tagline = branding['tagline'] as String? ?? 'Music Therapy Companion';
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('fetchFeatureToggles error: $e');
    }
  }


  static const _kUser = 'mu_user';
  static const _kEmail = 'mu_email';
  static const _kLoggedIn = 'mu_logged_in';
  static const _kBlocked = 'mu_blocked';
  static const _kLiked = 'mu_liked';
  static const _kHistory = 'mu_history';
  static const _kPass = 'mu_pass';
  static const _kDOB = 'mu_dob';
  static const _kAge = 'mu_age';
  static const _kGender = 'mu_gender';

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    _isLoggedIn = prefs.getBool(_kLoggedIn) ?? false;
    if (_isLoggedIn) {
      _userName = prefs.getString(_kUser) ?? '';
      _userEmail = prefs.getString(_kEmail) ?? '';
      _userPassword = prefs.getString(_kPass) ?? '';
      _userDOB = prefs.getString(_kDOB) ?? '';
      _userAge = prefs.getString(_kAge) ?? '';
      _userGender = prefs.getString(_kGender) ?? '';
    }

    final likedJson = prefs.getString(_kLiked);
    if (likedJson != null) {
      final list = jsonDecode(likedJson) as List<dynamic>;
      _likedSongs.clear();
      _likedSongs.addAll(list
          .map((e) => BlockedSong.fromJson(e as Map<String, dynamic>))
          .toList());
    }

    final histJson = prefs.getString(_kHistory);
    if (histJson != null) {
      final list = jsonDecode(histJson) as List<dynamic>;
      _history.clear();
      _history.addAll(list
          .map((e) => SessionRecord.fromJson(e as Map<String, dynamic>))
          .toList());
    }

    final blockedJson = prefs.getString(_kBlocked);
    if (blockedJson != null) {
      final list = jsonDecode(blockedJson) as List<dynamic>;
      _blockedSongs.clear();
      _blockedSongs.addAll(list
          .map((e) => BlockedSong.fromJson(e as Map<String, dynamic>))
          .toList());
    }

    // Fetch feature toggles whenever loading from prefs
    await fetchFeatureToggles();

    if (_isLoggedIn && _userEmail.isNotEmpty) {
      _startHeartbeat();
    }

    notifyListeners();
  }

  void _clearUserData() {
    _isLoggedIn = false;
    _userName = '';
    _userEmail = '';
    _userPassword = '';
    _userDOB = '';
    _userAge = '';
    _userGender = '';
    _inputText = '';
    _songs = [];
    _currentMood = '';
    _targetMood = '';
    _moodIntensity = 50;
    _history = [];
    _blockedSongs = [];
    _likedSongs = [];
    // ✅ _playedSongs is intentionally NOT cleared on logout
    // so played history persists per user across sessions.
    _activeTransitions = [];
    _sessionSongsPlayed = [];
    _sessionIntensities = [];
    _songsPlayedCount = 0;
    _sessionActiveDuration = Duration.zero;
    _lastPlaybackTick = null;
    _isPlaying = false;
    _currentVideoId = null;
    _playlistVersion++;
  }

  Future<void> login(String email, String password) async {
    // Clear any previous user's data before logging in
    _clearUserData();
    notifyListeners();

    final result = await ApiService.login(email: email, password: password);
    final user = result['user'] as Map<String, dynamic>;

    _userName = user['name'] ?? '';
    _userEmail = user['email'] ?? '';
    _userPassword = password;
    _userDOB = user['dob'] ?? '';
    _userAge = user['age'] ?? '';
    _userGender = user['gender'] ?? '';
    _isLoggedIn = true;

    if (_isLoggedIn && _userEmail.isNotEmpty) {
      ApiService.sendLifecycle(_userEmail, 'online');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedIn, true);
    await prefs.setString(_kUser, _userName);
    await prefs.setString(_kEmail, _userEmail);
    await prefs.setString(_kPass, _userPassword);
    await prefs.setString(_kDOB, _userDOB);
    await prefs.setString(_kAge, _userAge);
    await prefs.setString(_kGender, _userGender);

    // Fetch history, preferences, and played songs
    try {
      _history = await ApiService.getHistory(_userEmail);
      await _saveHistory();

      final prefsData = await ApiService.getPreferences(_userEmail);
      _blockedSongs = prefsData['blocked'] ?? [];
      _likedSongs = prefsData['liked'] ?? [];
      await _saveBlockedSongs();
      await _saveLikedSongs();

      // ✅ Pre-load played songs for all moods from backend
      // We won't know the mood until user enters text, so we'll load on-demand
      // per mood when getSongs is called (this is handled lazily in app_state)
    } catch (e) {
      debugPrint('AppState: Failed to sync data after login: $e');
    }

    // Fetch admin feature toggles
    fetchFeatureToggles();
    if (_isLoggedIn && _userEmail.isNotEmpty) {
      _startHeartbeat();
    }

    notifyListeners();
  }

  Future<void> logout() async {
    _stopHeartbeat();
    _clearUserData();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Complete purge for safety
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? dob,
    String? age,
    String? gender,
  }) async {
    await ApiService.register(
      name: name,
      email: email,
      password: password,
      dob: dob,
      age: age,
      gender: gender,
    );
    // Auto-login after registration
    await login(email, password);
  }

  Future<void> _saveBlockedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kBlocked, jsonEncode(_blockedSongs.map((b) => b.toJson()).toList()));
    if (_isLoggedIn) {
      ApiService.syncPreferences(_userEmail, _blockedSongs, _likedSongs)
          .catchError((e) => debugPrint('Sync preferences failed: $e'));
    }
  }

  Future<void> _saveLikedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kLiked, jsonEncode(_likedSongs.map((b) => b.toJson()).toList()));
    if (_isLoggedIn) {
      ApiService.syncPreferences(_userEmail, _blockedSongs, _likedSongs)
          .catchError((e) => debugPrint('Sync preferences failed: $e'));
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHistory,
        jsonEncode(_history.take(50).map((s) => s.toJson()).toList()));
    if (_isLoggedIn) {
      ApiService.syncHistory(_userEmail, _history)
          .catchError((e) => debugPrint('Sync history failed: $e'));
    }
  }

  // ── Mood emoji helper ──
  static String moodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'joyful':
        return '😄';
      case 'sad':
      case 'melancholic':
        return '😢';
      case 'calm':
      case 'relaxed':
        return '😌';
      case 'stressed':
      case 'anxious':
        return '😰';
      case 'angry':
        return '😤';
      case 'hopeful':
        return '🙂';
      case 'neutral':
        return '😐';
      case 'energetic':
        return '⚡';
      default:
        return '🎵';
    }
  }
}
