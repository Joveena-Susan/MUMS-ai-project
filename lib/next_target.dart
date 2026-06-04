import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'mood_input.dart';
import 'mooduplift_history.dart';
import 'settings.dart';

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
  runApp(const NextTargetApp());
}

// ─── Palette ──────────────────────────────────────────────────────────────────
const Color kOrange = Color(0xFFFB923C);
const Color kPink = Color(0xFFF472B6);
const Color kViolet = Color(0xFFC4B5FD);
const Color kBlue = Color(0xFF93C5FD);
const Color kGreen = Color(0xFFA7F3D0);
const Color kYellow = Color(0xFFFBBF24);

double _lerp(double a, double b, double t) => a + (b - a) * t;

class NextTargetApp extends StatelessWidget {
  const NextTargetApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Next Target',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(scaffoldBackgroundColor: const Color(0xFF000000)),
        home: const NextTargetScreen(),
      );
}

// ─── Step data ────────────────────────────────────────────────────────────────
enum _StepState { done, active, next, soon, goal }

class _StepData {
  final String emoji, name, desc;
  final _StepState state;
  const _StepData(this.emoji, this.name, this.desc, this.state);
}

// Base ladder definition (mood name + emoji + description)
const _kLadderNames = ['Sad', 'Calm', 'Neutral', 'Happy', 'Energised'];
const _kLadderEmoji = ['😢', '😌', '😐', '😄', '🔥'];
const _kLadderDesc = [
  'Starting point · Phase 1 complete',
  'Soothing phase · tension released',
  'You are here · Phase 2 in progress',
  'Almost there · final phase',
  'Goal state · journey complete',
];

/// Compute ladder steps dynamically from the user's current mood.
List<_StepData> _buildLadder(String currentMood) {
  final cur = currentMood.toLowerCase();
  int curIdx = _kLadderNames.indexWhere((n) => n.toLowerCase() == cur);
  if (curIdx < 0) curIdx = 0; // default to first if unknown
  return List.generate(_kLadderNames.length, (i) {
    _StepState state;
    if (i < curIdx) {
      state = _StepState.done;
    } else if (i == curIdx) {
      state = _StepState.active;
    } else if (i == curIdx + 1) {
      state = _StepState.next;
    } else if (i == _kLadderNames.length - 1) {
      state = _StepState.goal;
    } else {
      state = _StepState.soon;
    }
    return _StepData(
        _kLadderEmoji[i], _kLadderNames[i], _kLadderDesc[i], state);
  });
}

// ─── Main Screen ──────────────────────────────────────────────────────────────
class NextTargetScreen extends StatefulWidget {
  const NextTargetScreen({super.key});
  @override
  State<NextTargetScreen> createState() => _NextTargetScreenState();
}

class _NextTargetScreenState extends State<NextTargetScreen>
    with TickerProviderStateMixin {
  late final AnimationController _eyebrowCtrl;
  late final AnimationController _spineCtrl;
  late final AnimationController _ctaFloatCtrl;
  late final AnimationController _ctaRingCtrl;
  late final AnimationController _activePulseCtrl;

  // entrance stagger
  late final AnimationController _topBarCtrl;
  late final AnimationController _headCtrl;
  late final AnimationController _moodRowCtrl;
  late final AnimationController _sectionLblCtrl;
  late final AnimationController _ladderCtrl;
  late final AnimationController _finalCardCtrl;
  late final AnimationController _statsCtrl;
  late final AnimationController _ctaCtrl;
  late final AnimationController _tipCtrl;

  // animated counters
  late final AnimationController _counterCtrl;

  // mini player
  late final AnimationController _playerProgressCtrl;
  late final AnimationController _playerAlbumCtrl;
  int _bottomNavIdx = 1; // 0=home,1=mood,2=history,3=settings

  void _after(int ms, VoidCallback fn) =>
      Future.delayed(Duration(milliseconds: ms), () {
        if (mounted) fn();
      });

  @override
  void initState() {
    super.initState();

    _eyebrowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _spineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _ctaFloatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
    _ctaRingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _activePulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _counterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // entrance stagger
    _topBarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _headCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _moodRowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _sectionLblCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _ladderCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _finalCardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _statsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _ctaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _tipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _after(100, _headCtrl.forward);
    _after(180, _moodRowCtrl.forward);
    _after(240, _sectionLblCtrl.forward);
    _after(280, _ladderCtrl.forward);
    _after(320, _finalCardCtrl.forward);
    _after(360, _statsCtrl.forward);
    _after(400, _ctaCtrl.forward);
    _after(440, _tipCtrl.forward);

    // spine + counters fire 500ms after load
    _after(500, () {
      _spineCtrl.forward();
      _counterCtrl.forward();
    });

    // mini player
    _playerProgressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 228),
    )..forward();
    _playerAlbumCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _eyebrowCtrl.dispose();
    _spineCtrl.dispose();
    _ctaFloatCtrl.dispose();
    _ctaRingCtrl.dispose();
    _activePulseCtrl.dispose();
    _counterCtrl.dispose();
    _topBarCtrl.dispose();
    _headCtrl.dispose();
    _moodRowCtrl.dispose();
    _sectionLblCtrl.dispose();
    _ladderCtrl.dispose();
    _finalCardCtrl.dispose();
    _statsCtrl.dispose();
    _ctaCtrl.dispose();
    _tipCtrl.dispose();
    _playerProgressCtrl.dispose();
    _playerAlbumCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, cs) {
          final W = cs.maxWidth;
          final H = cs.maxHeight;
          return Stack(
            children: [
              _background(W, H),
              _scrollContent(W),
              Positioned(bottom: 0, left: 0, right: 0, child: _bottomChrome(W)),
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

  // ─── Scroll content ───────────────────────────────────────────────────────────
  Widget _scrollContent(double W) {
    final appState = Provider.of<AppState>(context);
    final isNoSession = appState.currentMood.isEmpty;

    return Positioned.fill(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(W * 0.067, 0, W * 0.067, 260),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _fadeUp(_topBarCtrl, _topBar()),
              const SizedBox(height: 16),
              if (isNoSession)
                _buildEmptyState()
              else ...[
                _fadeUp(_headCtrl, RepaintBoundary(child: _insightHeader())),
                const SizedBox(height: 14),
                _fadeUp(
                    _moodRowCtrl, RepaintBoundary(child: _moodTransitionRow())),
                const SizedBox(height: 14),
                _fadeUp(_sectionLblCtrl, _sectionLabel('Emotional Ladder')),
                const SizedBox(height: 10),
                _fadeUp(_ladderCtrl, RepaintBoundary(child: _ladderCard())),
                const SizedBox(height: 14),
                _fadeUp(
                    _finalCardCtrl, RepaintBoundary(child: _finalTargetCard())),
                const SizedBox(height: 14),
                _fadeUp(_statsCtrl, RepaintBoundary(child: _statsRow())),
                const SizedBox(height: 16),
                _fadeUp(_ctaCtrl, _ctaButton()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kViolet.withValues(alpha: 0.05),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 48,
              color: kViolet.withValues(alpha: 0.3),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Your journey awaits',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Start a new session on the home tab to see your progress and target moods here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.45),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Top bar ─────────────────────────────────────────────────────────────────
  Widget _topBar() {
    return Row(
      children: [
        const SizedBox(width: 36), // Placeholder for removed back button
        const Spacer(),
        Text(
          'YOUR PROGRESS',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.45),
            letterSpacing: 0.14 * 13,
          ),
        ),
        const Spacer(),
        // spacer placeholder to keep title centered
        const SizedBox(width: 36),
      ],
    );
  }

  // ─── Insight header ───────────────────────────────────────────────────────────
  Widget _insightHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // eyebrow
        Row(
          children: [
            AnimatedBuilder(
              animation: _eyebrowCtrl,
              builder: (_, __) => Transform.scale(
                scale: _lerp(1.0, 0.55, _eyebrowCtrl.value),
                child: Opacity(
                  opacity: _lerp(1.0, 0.35, _eyebrowCtrl.value),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kOrange.withValues(alpha: 0.70),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Emotional Journey',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.18 * 11,
                color: kOrange.withValues(alpha: 0.70),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Builder(builder: (ctx) {
          final appState = Provider.of<AppState>(ctx);
          final currentMood = appState.currentMood.toLowerCase();
          final startMood = (appState.activeTransitions.isNotEmpty
                  ? appState.activeTransitions.first.from
                  : appState.currentMood)
              .toLowerCase();

          String part1 = "You are ";
          String part2 = "improving!";
          String part3 = "\nKeep going forward";

          if (appState.activeTransitions.isEmpty) {
            part1 = "Let's start ";
            part2 = "the journey!";
            part3 = "\nExpress your feelings above";
          } else {
            final startIndex = AppState.kMoodLadder.indexOf(startMood);
            final currentIndex = AppState.kMoodLadder.indexOf(currentMood);

            if (currentIndex > startIndex) {
              // Improving
              part1 = "You are ";
              part2 = "ascending!";
              part3 = "\nIncredible progress so far";
            } else if (currentIndex < startIndex) {
              // Declining
              part1 = "Stay ";
              part2 = "strong!";
              part3 = "\nLow moments are only temporary";
            } else {
              // Same mood
              part1 = "Stay ";
              part2 = "steady!";
              part3 = "\nYou're doing great just by being here";
            }
          }

          return RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 28,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
                color: Color(0xFFF0F0FF),
                height: 1.28,
              ),
              children: [
                TextSpan(text: part1),
                WidgetSpan(
                  child: ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [kOrange, kPink],
                    ).createShader(b),
                    child: Text(
                      part2,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.normal,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                TextSpan(text: part3),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─── Mood transition row ──────────────────────────────────────────────────────
  Widget _moodTransitionRow() {
    return Builder(builder: (ctx) {
      final appState = Provider.of<AppState>(ctx, listen: false);
      final curMood =
          appState.currentMood.isNotEmpty ? appState.currentMood : 'Neutral';
      final tgtMood =
          appState.targetMood.isNotEmpty ? appState.targetMood : 'Happy';
      final curEmoji = AppState.moodEmoji(curMood);
      final tgtEmoji = AppState.moodEmoji(tgtMood);
      final isEnergised = curMood.toLowerCase() == 'energised';

      return Row(
        children: [
          Expanded(
            child: _moodCardSm(
              label: 'Current Mood',
              emoji: curEmoji,
              name: curMood[0].toUpperCase() + curMood.substring(1),
              isCurrent: true,
            ),
          ),
          const SizedBox(width: 10),
          // arrow or check
          Column(
            children: [
              Container(
                width: 26,
                height: 2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      kBlue.withValues(alpha: 0.40),
                      isEnergised
                          ? kGreen.withValues(alpha: 0.65)
                          : kOrange.withValues(alpha: 0.65)
                    ],
                  ),
                ),
                child: isEnergised
                    ? Icon(Icons.check_circle_rounded,
                        size: 10, color: kGreen.withValues(alpha: 0.8))
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                isEnergised ? 'goal' : 'next',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.28),
                  letterSpacing: 0.06 * 9,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _moodCardSm(
              label: isEnergised ? 'Goal Reached' : 'Next Target',
              emoji: isEnergised ? '🏆' : tgtEmoji,
              name: isEnergised
                  ? 'Final Mood'
                  : (tgtMood[0].toUpperCase() + tgtMood.substring(1)),
              isTarget: true,
              isGoal: isEnergised,
            ),
          ),
        ],
      );
    });
  }

  Widget _moodCardSm({
    required String label,
    required String emoji,
    required String name,
    bool isCurrent = false,
    bool isTarget = false,
    bool isGoal = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: isGoal
                ? const Color(0xFFA7F3D0).withValues(alpha: 0.25)
                : isCurrent
                    ? kBlue.withValues(alpha: 0.09)
                    : isTarget
                        ? null
                        : Colors.white.withValues(alpha: 0.06),
            gradient: isTarget && !isGoal
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      kOrange.withValues(alpha: 0.12),
                      kPink.withValues(alpha: 0.10),
                    ],
                  )
                : isGoal
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFA7F3D0).withValues(alpha: 0.20),
                          const Color(0xFF93C5FD).withValues(alpha: 0.15),
                        ],
                      )
                    : null,
            border: Border.all(
              color: isGoal
                  ? const Color(0xFFA7F3D0).withValues(alpha: 0.50)
                  : isCurrent
                      ? kBlue.withValues(alpha: 0.24)
                      : isTarget
                          ? kOrange.withValues(alpha: 0.36)
                          : Colors.white.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.10),
                offset: const Offset(0, 2),
                blurRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.18),
                offset: const Offset(0, -1),
                blurRadius: 0,
              ),
              BoxShadow(
                color: isTarget
                    ? kOrange.withValues(alpha: 0.14)
                    : const Color(0xFF000000).withValues(alpha: 0.25),
                blurRadius: isTarget ? 28 : 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // top shine
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 36,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // centered content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    label.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.16 * 9,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(emoji, style: const TextStyle(fontSize: 30)),
                  const SizedBox(height: 6),
                  isTarget
                      ? ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [kOrange, kPink],
                          ).createShader(b),
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          name,
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isCurrent
                                ? kBlue.withValues(alpha: 0.92)
                                : Colors.white.withValues(alpha: 0.90),
                          ),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Section label ────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.12 * 11,
            color: Colors.white.withValues(alpha: 0.30),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.transparent
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Ladder card ─────────────────────────────────────────────────────────────
  Widget _ladderCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.10),
                offset: const Offset(0, 2),
                blurRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.18),
                offset: const Offset(0, -1),
                blurRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.25),
                blurRadius: 32,
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
                height: 60,
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x14FFFFFF), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Selector<AppState, String>(
                // PERF: Rebuild ladder only when currentMood changes
                selector: (_, state) => state.currentMood,
                builder: (_, currentMood, __) {
                  final steps = _buildLadder(currentMood);
                  // Compute spine fill fraction based on current mood
                  final cur = currentMood.toLowerCase();
                  int curIdx =
                      _kLadderNames.indexWhere((n) => n.toLowerCase() == cur);
                  if (curIdx < 0) curIdx = 0;
                  // fraction: center of active step / total height
                  final spineFraction = (curIdx + 0.5) / steps.length;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── spine ──
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 4, top: 4, bottom: 4),
                        child: SizedBox(
                          width: 2,
                          height: steps.length * 62.0,
                          child: Stack(
                            children: [
                              // base spine
                              Container(
                                width: 2,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0x8093C5FD),
                                      Color(0x72C4B5FD),
                                      Color(0x8CFB923C),
                                      Color(0x99F472B6),
                                    ],
                                  ),
                                ),
                              ),
                              // progress overlay
                              AnimatedBuilder(
                                animation: _spineCtrl,
                                builder: (_, __) {
                                  final pct = CurvedAnimation(
                                    parent: _spineCtrl,
                                    curve: const Cubic(0.22, 1, 0.36, 1),
                                  ).value;
                                  final h = _lerp(
                                    0,
                                    steps.length * 62.0 * spineFraction,
                                    pct,
                                  );
                                  return Positioned(
                                    top: 0,
                                    left: -2,
                                    child: Container(
                                      width: 6,
                                      height: h,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(3),
                                        color: kOrange.withValues(alpha: 0.90),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                kOrange.withValues(alpha: 0.80),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // ── steps ──
                      Expanded(
                        child: Column(
                          children: steps.map((s) => _ladderStep(s)).toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ladderStep(_StepData step) {
    final isDone = step.state == _StepState.done;
    final isActive = step.state == _StepState.active;
    final isNext = step.state == _StepState.next;
    final isGoal = step.state == _StepState.goal;

    Color nodeColor, nodeInner, nodeBorder;
    if (isDone) {
      nodeColor = kGreen.withValues(alpha: 0.12);
      nodeBorder = kGreen.withValues(alpha: 0.70);
      nodeInner = kGreen.withValues(alpha: 0.90);
    } else if (isActive) {
      nodeColor = kOrange.withValues(alpha: 0.16);
      nodeBorder = kOrange.withValues(alpha: 0.80);
      nodeInner = kOrange;
    } else {
      nodeColor = const Color(0xFF130F1E);
      nodeBorder = Colors.white.withValues(alpha: 0.18);
      nodeInner = Colors.white.withValues(alpha: 0.22);
    }

    Widget nodeWidget = AnimatedBuilder(
      animation: _activePulseCtrl,
      builder: (_, __) {
        final glow = isActive
            ? _lerp(0.50, 0.85, _activePulseCtrl.value)
            : (isDone ? 0.35 : 0.0);
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: nodeColor,
            border: Border.all(color: nodeBorder, width: 2),
            boxShadow: glow > 0
                ? [
                    BoxShadow(
                      color:
                          (isActive ? kOrange : kGreen).withValues(alpha: glow),
                      blurRadius: isActive ? 14 : 8,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: nodeInner,
              ),
            ),
          ),
        );
      },
    );

    Color nameColor;
    if (isDone) {
      nameColor = kGreen.withValues(alpha: 0.75);
    } else if (isActive) {
      nameColor = Colors.white.withValues(alpha: 0.95);
    } else if (isNext) {
      nameColor = kYellow.withValues(alpha: 0.80);
    } else {
      nameColor = Colors.white.withValues(alpha: 0.50);
    }

    Widget tag;
    if (isDone) {
      tag = _tag(
        '✓ Done',
        bg: kGreen.withValues(alpha: 0.12),
        fg: kGreen.withValues(alpha: 0.80),
        border: kGreen.withValues(alpha: 0.22),
      );
    } else if (isActive) {
      tag = _tag(
        'Now',
        bg: kOrange.withValues(alpha: 0.16),
        fg: const Color(0xFFFC9B60),
        border: kOrange.withValues(alpha: 0.36),
        glow: true,
      );
    } else if (isNext) {
      tag = _tag(
        'Next',
        bg: kYellow.withValues(alpha: 0.10),
        fg: kYellow.withValues(alpha: 0.80),
        border: kYellow.withValues(alpha: 0.20),
      );
    } else if (isGoal) {
      tag = _tag(
        '✦ Goal',
        bg: null,
        fg: const Color(0xFFFC9B60),
        border: kOrange.withValues(alpha: 0.28),
        gradient: LinearGradient(
          colors: [
            kOrange.withValues(alpha: 0.16),
            kPink.withValues(alpha: 0.14)
          ],
        ),
      );
    } else {
      tag = _tag(
        'Soon',
        bg: Colors.white.withValues(alpha: 0.06),
        fg: Colors.white.withValues(alpha: 0.38),
        border: Colors.white.withValues(alpha: 0.10),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          // node positioned to align with spine
          Transform.translate(offset: const Offset(-25, 0), child: nodeWidget),
          const SizedBox(width: 6),
          Text(
            step.emoji,
            style: const TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: nameColor,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    decorationColor: kGreen.withValues(alpha: 0.30),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  step.desc,
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        Colors.white.withValues(alpha: isActive ? 0.48 : 0.26),
                  ),
                ),
              ],
            ),
          ),
          tag,
        ],
      ),
    );
  }

  Widget _tag(
    String text, {
    required Color fg,
    required Color border,
    Color? bg,
    Gradient? gradient,
    bool glow = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: bg,
        gradient: gradient,
        border: Border.all(color: border),
        boxShadow: glow
            ? [
                BoxShadow(
                    color: kOrange.withValues(alpha: 0.18), blurRadius: 10)
              ]
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.08 * 9,
          color: fg,
        ),
      ),
    );
  }

  // ─── Final target card ────────────────────────────────────────────────────────
  Widget _finalTargetCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kPink.withValues(alpha: 0.14),
                kViolet.withValues(alpha: 0.12)
              ],
            ),
            border: Border.all(color: kPink.withValues(alpha: 0.40)),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.14),
                offset: const Offset(0, 2),
                blurRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.18),
                offset: const Offset(0, -1),
                blurRadius: 0,
              ),
              BoxShadow(
                color: kPink.withValues(alpha: 0.16),
                blurRadius: 32,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 44,
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x1AFFFFFF), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  // icon pill
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              kPink.withValues(alpha: 0.26),
                              kViolet.withValues(alpha: 0.20),
                            ],
                          ),
                          border:
                              Border.all(color: kPink.withValues(alpha: 0.40)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.18),
                              offset: const Offset(0, 2),
                              blurRadius: 0,
                            ),
                            BoxShadow(
                              color: kPink.withValues(alpha: 0.20),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: 27,
                              child: Container(
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0x2CFFFFFF),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Center(
                              child: Text('🔥', style: TextStyle(fontSize: 26)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FINAL TARGET MOOD',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.16 * 10,
                            color: kPink.withValues(alpha: 0.80),
                          ),
                        ),
                        const SizedBox(height: 5),
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [kPink, kViolet],
                          ).createShader(b),
                          child: const Text(
                            'Energised',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Goal state · journey complete',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.45),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // goal badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      gradient: LinearGradient(
                        colors: [
                          kOrange.withValues(alpha: 0.20),
                          kPink.withValues(alpha: 0.18),
                        ],
                      ),
                      border:
                          Border.all(color: kOrange.withValues(alpha: 0.38)),
                      boxShadow: [
                        BoxShadow(
                          color: kOrange.withValues(alpha: 0.14),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Text(
                      '✦ Goal',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.08 * 10,
                        color: const Color(0xFFFC9B60).withValues(alpha: 0.95),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Stats row ────────────────────────────────────────────────────────────────
  Widget _statsRow() {
    return Selector<AppState, (int, String)>(
      // PERF: Isolate stats row to rebuild only when songsPlayedCount or currentMood changes
      selector: (_, state) => (state.songsPlayedCount, state.currentMood),
      builder: (_, data, __) {
        // Songs played = number of songs in current session
        final songsPlayed = data.$1;
        // All mood ladder steps
        final allMoods = ['sad', 'calm', 'neutral', 'happy', 'energised'];
        final curMood = data.$2.toLowerCase();
        final curIdx = allMoods.indexOf(curMood);
        // Steps already climbed (from start to current)
        final stepsUp = curIdx > 0 ? curIdx : 0;
        // Steps remaining (from current to final goal)
        final goalIdx = allMoods.length - 1; // 'energised'
        final stepsLeft = goalIdx - curIdx > 0 ? goalIdx - curIdx : 0;
        return Row(
          children: [
            Expanded(child: _statPill('Steps Up', stepsUp, _counterCtrl)),
            const SizedBox(width: 10),
            Expanded(
                child: _statPill('Songs Played', songsPlayed, _counterCtrl)),
            const SizedBox(width: 10),
            Expanded(child: _statPill('Steps Left', stepsLeft, _counterCtrl)),
          ],
        );
      },
    );
  }

  Widget _statPill(String label, int target, AnimationController ctrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.10),
                offset: const Offset(0, 2),
                blurRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.18),
                offset: const Offset(0, -1),
                blurRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.20),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 28,
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x1AFFFFFF), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  AnimatedBuilder(
                    animation: ctrl,
                    builder: (_, __) {
                      final v = CurvedAnimation(
                        parent: ctrl,
                        curve: Curves.easeOutCubic,
                      ).value;
                      final val = (v * target).round();
                      return ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [kOrange, kPink],
                        ).createShader(b),
                        child: Text(
                          val == 0 ? '—' : '$val',
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.12 * 9,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── CTA button ───────────────────────────────────────────────────────────────
  Widget _ctaButton() {
    return AnimatedBuilder(
      animation: _ctaFloatCtrl,
      builder: (_, __) {
        const floatY = 0.0;
        return Transform.translate(
          offset: const Offset(0, floatY),
          child: Stack(
            children: [
              // pulse ring
              AnimatedBuilder(
                animation: _ctaRingCtrl,
                builder: (_, __) {
                  final s = _lerp(1.0, 1.04, _ctaRingCtrl.value);
                  final op = _lerp(0.5, 0.0, _ctaRingCtrl.value);
                  return Transform.scale(
                    scale: s,
                    child: Opacity(
                      opacity: op,
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(21),
                          border: Border.all(
                              color: kOrange.withValues(alpha: 0.16)),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const _PressableCtaBtn(),
            ],
          ),
        );
      },
    );
  }

  // ─── Bottom chrome: mini player + nav bar ────────────────────────────────────
  Widget _bottomChrome(double W) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _miniPlayer(W),
        const SizedBox(height: 6),
        _bottomNavBar(W),
        const SizedBox(height: 12),
      ],
    );
  }

  // ─── Mini player ─────────────────────────────────────────────────────────────
  Widget _miniPlayer(double W) {
    // PERF: Removed full-tree Consumer
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            Provider.of<AppState>(context, listen: false).openPlayer();
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            height: 64,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFF2A1C30).withValues(alpha: 0.85),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.14)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.12),
                      offset: const Offset(0, 1),
                      blurRadius: 0,
                    ),
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.30),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: const Color(0xFFFF9A6B).withValues(alpha: 0.06),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 32,
                      child: Container(
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x18FFFFFF), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 2,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(20),
                        ),
                        child: Selector<AppState, double>(
                          // PERF: Isolate high-frequency progress bar updates
                          selector: (_, state) => state.playbackProgress,
                          builder: (_, progressVal, __) {
                            final progress = progressVal.clamp(0.0, 1.0);
                            return LinearProgressIndicator(
                              value: progress,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.08),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF9A6B),
                              ),
                              minHeight: 2,
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 14, 2),
                      child: Row(
                        children: [
                          Selector<AppState, bool>(
                            // PERF: Isolate play/pause album rotation
                            selector: (_, state) => state.isPlaying,
                            builder: (_, isPlaying, __) {
                              return AnimatedBuilder(
                                animation: _playerAlbumCtrl,
                                builder: (_, __) => Transform.rotate(
                                  angle: isPlaying
                                      ? _playerAlbumCtrl.value *
                                          2 *
                                          3.1415926535
                                      : 0,
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF3D1F0A),
                                          Color(0xFF1A0F20),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.20),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF9A6B)
                                              .withValues(alpha: 0.25),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '🎵',
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Selector<AppState, (String, String, String)>(
                              // PERF: Extract song info changes
                              selector: (_, state) {
                                final hasSongs = state.songs.isNotEmpty;
                                final song = hasSongs
                                    ? state.songs[state.currentTrackIndex
                                        .clamp(0, state.songs.length - 1)]
                                    : null;
                                return (
                                  song?.title ?? 'No song playing',
                                  song?.artist ?? 'Analyze your mood first',
                                  song?.emoji ?? '🎵'
                                );
                              },
                              builder: (context, songData, _) {
                                final title = songData.$1;
                                final artist = songData.$2;
                                final emoji = songData.$3;
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ShaderMask(
                                      shaderCallback: (b) =>
                                          const LinearGradient(
                                        colors: [
                                          Color(0xFFF0F0FF),
                                          Color(0xFFDDD0F5),
                                        ],
                                      ).createShader(b),
                                      child: Text(
                                        '$emoji  $title',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: 0.01 * 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      artist,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white
                                            .withValues(alpha: 0.50),
                                        fontWeight: FontWeight.w400,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          Selector<AppState, bool>(
                            selector: (_, state) => state.featureSkipSong,
                            builder: (context, skip, _) {
                              if (!skip) return const SizedBox();
                              return Row(
                                children: [
                                  const SizedBox(width: 8),
                                  _playerBtn(
                                    icon: Icons.skip_previous_rounded,
                                    onTap: () {
                                      Provider.of<AppState>(context, listen: false)
                                          .previousTrack();
                                    },
                                    size: 22,
                                  ),
                                ]
                              );
                            }
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              final st =
                                  Provider.of<AppState>(context, listen: false);
                              st.setPlaying(!st.isPlaying);
                            },
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFFFF9A6B)
                                        .withValues(alpha: 0.35),
                                    const Color(0xFFE48DFF)
                                        .withValues(alpha: 0.25),
                                  ],
                                ),
                                border: Border.all(
                                  color: const Color(0xFFFF9A6B)
                                      .withValues(alpha: 0.50),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.20),
                                    offset: const Offset(0, 1),
                                    blurRadius: 0,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFFF9A6B)
                                        .withValues(alpha: 0.25),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    height: 19,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0x28FFFFFF),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Selector<AppState, bool>(
                                    // PERF: Isolate play button icon updates
                                    selector: (_, state) => state.isPlaying,
                                    builder: (_, isPlaying, __) {
                                      return Center(
                                        child: Icon(
                                          isPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Selector<AppState, bool>(
                            selector: (_, state) => state.featureSkipSong,
                            builder: (context, skip, _) {
                              if (!skip) return const SizedBox();
                              return Row(
                                children: [
                                  const SizedBox(width: 8),
                                  _playerBtn(
                                    icon: Icons.skip_next_rounded,
                                    onTap: () {
                                      Provider.of<AppState>(context, listen: false)
                                          .nextTrack();
                                    },
                                    size: 22,
                                  ),
                                ]
                              );
                            }
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _playerBtn({
    required IconData icon,
    required VoidCallback onTap,
    double size = 20,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.14),
                  offset: const Offset(0, 1),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.15),
                  offset: const Offset(0, -1),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 16,
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x20FFFFFF), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    icon,
                    color: Colors.white.withValues(alpha: 0.75),
                    size: size,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Bottom nav bar ───────────────────────────────────────────────────────────
  Widget _bottomNavBar(double W) {
    const items = [
      (Icons.home_rounded, 'Home'),
      (Icons.self_improvement_rounded, 'Mood'),
      (Icons.history_rounded, 'History'),
      (Icons.settings_rounded, 'Settings'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      height: 68,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.10),
                  offset: const Offset(0, 1),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.15),
                  offset: const Offset(0, -1),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 34,
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x14FFFFFF), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(items.length, (i) {
                    final item = items[i];
                    final sel = _bottomNavIdx == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (i == _bottomNavIdx) return;
                          setState(() => _bottomNavIdx = i);
                          if (i == 0) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MoodInputScreen(),
                              ),
                            );
                          } else if (i == 2) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HistoryScreen(),
                              ),
                            );
                          } else if (i == 3) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            );
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.center,
                          margin: const EdgeInsets.all(6),
                          decoration: sel
                              ? BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      kOrange.withValues(alpha: 0.24),
                                      kPink.withValues(alpha: 0.16),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: kOrange.withValues(alpha: 0.40),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.white.withValues(alpha: 0.22),
                                      offset: const Offset(0, 1),
                                      blurRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF000000)
                                          .withValues(alpha: 0.18),
                                      offset: const Offset(0, -1),
                                      blurRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: kOrange.withValues(alpha: 0.18),
                                      blurRadius: 14,
                                    ),
                                  ],
                                )
                              : null,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (sel)
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  height: 28,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0x24FFFFFF),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedScale(
                                    scale: sel ? 1.10 : 1.0,
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOutCubic,
                                    child: Icon(
                                      item.$1,
                                      size: 22,
                                      color: sel
                                          ? kOrange
                                          : Colors.white
                                              .withValues(alpha: 0.45),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 250),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: sel
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: sel
                                          ? kOrange.withValues(alpha: 0.95)
                                          : Colors.white
                                              .withValues(alpha: 0.40),
                                      letterSpacing: 0.02 * 10,
                                    ),
                                    child: Text(item.$2),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Fade-up helper ───────────────────────────────────────────────────────────
  Widget _fadeUp(AnimationController ctrl, Widget child) {
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
            child: child,
          ),
        );
      },
    );
  }
}

// ─── Pressable CTA button ─────────────────────────────────────────────────────
class _PressableCtaBtn extends StatefulWidget {
  const _PressableCtaBtn();
  @override
  State<_PressableCtaBtn> createState() => _PressableCtaBtnState();
}

class _PressableCtaBtnState extends State<_PressableCtaBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _glowAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween(
      begin: 1.0,
      end: 0.955,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
    _glowAnim = Tween(
      begin: 0.18,
      end: 0.55,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    _pressCtrl.forward();
    setState(() => _pressed = true);
  }

  void _onTapUp(_) {
    _pressCtrl.reverse();
    setState(() => _pressed = false);
  }

  void _onTapCancel() {
    _pressCtrl.reverse();
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () {
        Provider.of<AppState>(context, listen: false).openPlayer();
      },
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (_, __) => Transform.scale(
          scale: _scaleAnim.value,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _pressed
                        ? [
                            kOrange.withValues(alpha: 0.50),
                            kPink.withValues(alpha: 0.42)
                          ]
                        : [
                            kOrange.withValues(alpha: 0.28),
                            kPink.withValues(alpha: 0.22)
                          ],
                  ),
                  border: Border.all(
                    color: _pressed
                        ? kOrange.withValues(alpha: 0.70)
                        : kOrange.withValues(alpha: 0.42),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white
                          .withValues(alpha: _pressed ? 0.55 : 0.40),
                      offset: const Offset(0, 1),
                      blurRadius: 0,
                    ),
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.24),
                      offset: const Offset(0, -1),
                      blurRadius: 0,
                    ),
                    BoxShadow(
                      color: kOrange.withValues(alpha: _glowAnim.value),
                      blurRadius: _pressed ? 48 : 32,
                      offset: const Offset(0, 8),
                    ),
                    if (_pressed)
                      BoxShadow(
                        color: kOrange.withValues(alpha: 0.30),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Stack(
                  children: [
                    // top shine — dims on press
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 27,
                      child: AnimatedOpacity(
                        opacity: _pressed ? 0.4 : 1.0,
                        duration: const Duration(milliseconds: 80),
                        child: Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(18),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x40FFFFFF),
                                Color(0x0AFFFFFF),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // bottom shadow
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 20,
                      child: Container(
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(18),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0x28000000), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    // ripple overlay when pressed
                    if (_pressed)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 0.9,
                              colors: [
                                Colors.white.withValues(alpha: 0.10),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    // label
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '✦',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withValues(
                                alpha: _pressed ? 0.70 : 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Continue Journey',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(
                                alpha: _pressed ? 0.75 : 1.0,
                              ),
                              letterSpacing: 0.03 * 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
