import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'api_service.dart';
import 'next_target.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const MoodUpliftApp());
}

// ─── Palette ──────────────────────────────────────────────────────────────────
const Color kOrange = Color(0xFFFB923C); // rgba(251,146,60)
const Color kPink = Color(0xFFF472B6); // rgba(244,114,182)
const Color kPurple = Color(0xFFC4B5FD); // rgba(196,181,253)
const Color kGreen = Color(0xFFA7F3D0); // rgba(167,243,208)
const Color kBlue = Color(0xFF93C5FD); // rgba(147,197,253)

double _lerp(double a, double b, double t) => a + (b - a) * t;

class MoodUpliftApp extends StatelessWidget {
  const MoodUpliftApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Mood Uplift',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: const Color(0xFF000000)),
      home: const ProcessingScreen(),
    );
  }
}

// ─── Step model ───────────────────────────────────────────────────────────────
enum StepState { pending, active, done }

class AnalysisStep {
  final String title;
  final String sub;
  final String icon;
  final String doneLabel;
  StepState state;
  AnalysisStep({
    required this.title,
    required this.sub,
    required this.icon,
    required this.doneLabel,
    this.state = StepState.pending,
  });
}

// ─── Processing Screen ────────────────────────────────────────────────────────
class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});
  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with TickerProviderStateMixin {
  // ── bg shift (brightness pulse) ──
  late final AnimationController _bgCtrl;

  // ── core orb pulse ──
  late final AnimationController _orbPulseCtrl;

  // ── arc spin ──
  late final AnimationController _arcCtrl;

  // ── glow disc pulse ──
  late final AnimationController _glowCtrl;

  // ── ripple rings (3 staggered) ──
  late final List<AnimationController> _ringCtrl;

  // ── waveform bars (12) ──
  late final List<AnimationController> _wbarCtrl;

  // ── fade-up entrance controllers ──
  late final AnimationController _waveformFadeCtrl;
  late final AnimationController _headlineFadeCtrl;
  late final AnimationController _sublineFadeCtrl;
  late final AnimationController _stepsFadeCtrl;
  late final AnimationController _hintFadeCtrl;
  late final AnimationController _cancelFadeCtrl;

  // ── hint dots blink ──
  late final List<AnimationController> _hintDotCtrl;

  // ── step sequencer ──
  final List<AnalysisStep> _steps = [
    AnalysisStep(
        title: 'Reading your words',
        sub: 'Natural language processing',
        icon: '🔍',
        doneLabel: 'Done'),
    AnalysisStep(
        title: 'Detecting emotion layers',
        sub: 'Sentiment & intensity mapping',
        icon: '🌊',
        doneLabel: 'Done'),
    AnalysisStep(
        title: 'Matching music profile',
        sub: 'Energy, tempo & mood fit',
        icon: '🎵',
        doneLabel: 'Done'),
    AnalysisStep(
        title: 'Curating your playlist',
        sub: 'Personalising recommendations',
        icon: '✨',
        doneLabel: 'Ready'),
  ];

  void _after(int ms, VoidCallback fn) =>
      Future.delayed(Duration(milliseconds: ms), () {
        if (mounted) fn();
      });

  @override
  void initState() {
    super.initState();

    // ── bg shift ──
    _bgCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat(reverse: true);

    // ── core orb pulse ──
    _orbPulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat(reverse: true);

    // ── arc spin ──
    _arcCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();

    // ── glow disc ──
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat(reverse: true);

    // ── ripple rings ──
    _ringCtrl = List.generate(3, (i) {
      final c = AnimationController(
          vsync: this, duration: const Duration(seconds: 3));
      _after(i * 1000, () => c.repeat());
      return c;
    });

    // ── waveform bars ──
    const wbarDur = [
      900,
      700,
      1100,
      800,
      600,
      1000,
      750,
      850,
      650,
      950,
      720,
      1050
    ];
    const wbarDelay = [0, 120, 50, 200, 80, 160, 30, 220, 100, 180, 60, 140];
    _wbarCtrl = List.generate(12, (i) {
      final c = AnimationController(
          vsync: this, duration: Duration(milliseconds: wbarDur[i]));
      _after(wbarDelay[i], () => c.repeat(reverse: true));
      return c;
    });

    // ── entrance fades ──
    _waveformFadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _headlineFadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _sublineFadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _stepsFadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _hintFadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _cancelFadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    _after(300, _waveformFadeCtrl.forward);
    _after(150, _headlineFadeCtrl.forward);
    _after(250, _sublineFadeCtrl.forward);
    _after(400, _stepsFadeCtrl.forward);
    _after(550, _hintFadeCtrl.forward);
    _after(650, _cancelFadeCtrl.forward);

    // ── hint dots ──
    _hintDotCtrl = List.generate(3, (i) {
      final c = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 1800));
      _after(i * 300, () => c.repeat(reverse: true));
      return c;
    });

    // ── start API instantly ──
    _after(900, () => _callApi());
  }

  Future<void> _callApi() async {
    if (!mounted) return;
    setState(() {
      _steps[0].state = StepState.done;
      _steps[1].state = StepState.active;
    });

    final appState = Provider.of<AppState>(context, listen: false);
    try {
      final batch = await ApiService.getSongs(
        text: appState.inputText,
        languages: appState.selectedLanguages,
        email: appState.userEmail,
        blocked: appState.blockedSongs,
        liked: appState.likedSongs,
      );
      if (!mounted) return;

      setState(() {
        _steps[1].state = StepState.done;
        _steps[2].state = StepState.done;
        _steps[3].state = StepState.done;
      });
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      appState.setApiResult(
        currentMood: batch.currentMood,
        targetMood: batch.targetMood,
        intensity: batch.intensity,
        songs: batch.songs,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const NextTargetScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Could not fetch songs: $e\nIs the backend running?')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _orbPulseCtrl.dispose();
    _arcCtrl.dispose();
    _glowCtrl.dispose();
    for (final c in _ringCtrl) {
      c.dispose();
    }
    for (final c in _wbarCtrl) {
      c.dispose();
    }
    _waveformFadeCtrl.dispose();
    _headlineFadeCtrl.dispose();
    _sublineFadeCtrl.dispose();
    _stepsFadeCtrl.dispose();
    _hintFadeCtrl.dispose();
    _cancelFadeCtrl.dispose();
    for (final c in _hintDotCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: LayoutBuilder(builder: (context, constraints) {
        final W = constraints.maxWidth;
        final H = constraints.maxHeight;
        return Stack(children: [
          _background(W, H),
          // centered content
          _content(W, H),
        ]);
      }),
    );
  }

  // ─── Background ──────────────────────────────────────────────────────────────
  Widget _background(double W, double H) {
    return const Positioned.fill(
      child: ColoredBox(color: Color(0xFF000000)),
    );
  }

  // ─── Full centered content ────────────────────────────────────────────────────
  Widget _content(double W, double H) {
    return Positioned.fill(
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: SizedBox(
            height: H -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Pulse stage ──
                _pulseStage(W),
                SizedBox(height: H * 0.062),
                // ── Waveform ──
                _fadeUp(_waveformFadeCtrl, _waveform()),
                SizedBox(height: H * 0.052),
                // ── Headline ──
                _fadeUp(_headlineFadeCtrl, _headline()),
                const SizedBox(height: 12),
                // ── Subline ──
                _fadeUp(
                  _sublineFadeCtrl,
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: W * 0.12),
                    child: Text(
                      'Our AI is reading the emotional patterns in your words to find music that truly resonates.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.42),
                          height: 1.6,
                          letterSpacing: 0.14),
                    ),
                  ),
                ),
                SizedBox(height: H * 0.045),
                // ── Steps ──
                _fadeUp(
                  _stepsFadeCtrl,
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: W * 0.072),
                    child: Column(
                      children: _steps
                          .asMap()
                          .entries
                          .map(
                            (e) => Padding(
                              padding: EdgeInsets.only(
                                  bottom: e.key < _steps.length - 1 ? 10 : 0),
                              child: _stepTile(e.value),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                // ── Bottom hint ──
                _fadeUp(
                  _hintFadeCtrl,
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...List.generate(
                            3,
                            (i) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _hintDot(i),
                                )),
                        Text('This takes just a moment',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.30),
                                letterSpacing: 0.48)),
                      ],
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

  // ─── Pulse stage ─────────────────────────────────────────────────────────────
  Widget _pulseStage(double W) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(alignment: Alignment.center, children: [
        // 3 ripple rings
        ..._ringCtrl.asMap().entries.map((e) => _rippleRing(e.key, e.value)),
        // glow disc
        _glowDisc(),
        // core orb
        _coreOrb(),
      ]),
    );
  }

  Widget _rippleRing(int idx, AnimationController ctrl) {
    final colors = [
      kOrange.withValues(alpha: 0.25),
      kPink.withValues(alpha: 0.20),
      kPurple.withValues(alpha: 0.15),
    ];
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final v = ctrl.value;
        final scale = _lerp(0.5, 2.2, v);
        final opacity = _lerp(0.9, 0.0, v);
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors[idx], width: 1),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _glowDisc() {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) {
        final v = _glowCtrl.value;
        return Transform.scale(
          scale: _lerp(1.0, 1.25, v),
          child: Opacity(
            opacity: _lerp(0.7, 1.0, v),
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    kOrange.withValues(alpha: 0.28),
                    kPink.withValues(alpha: 0.18),
                    Colors.transparent,
                  ], stops: const [
                    0,
                    0.5,
                    1
                  ]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _coreOrb() {
    return AnimatedBuilder(
      animation: _orbPulseCtrl,
      builder: (_, __) {
        final v = _orbPulseCtrl.value;
        final glow1 = _lerp(0.25, 0.38, v);
        final glow2 = _lerp(0.06, 0.08, v);
        final glow3 = _lerp(0.04, 0.05, v);
        final spread1 = _lerp(12.0, 18.0, v);
        final spread2 = _lerp(22.0, 32.0, v);
        return Transform.scale(
          scale: _lerp(1.0, 1.08, v),
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
              boxShadow: [
                BoxShadow(
                    color: Colors.white.withValues(alpha: 0.42),
                    offset: const Offset(0, 1),
                    blurRadius: 0),
                BoxShadow(
                    color: const Color(0xFF000000).withValues(alpha: 0.22),
                    offset: const Offset(0, -2),
                    blurRadius: 0),
                BoxShadow(
                    color: kOrange.withValues(alpha: glow1),
                    blurRadius: 40,
                    offset: const Offset(0, 12)),
                BoxShadow(
                    color: kOrange.withValues(alpha: glow2),
                    blurRadius: 0,
                    spreadRadius: spread1),
                BoxShadow(
                    color: kPink.withValues(alpha: glow3),
                    blurRadius: 0,
                    spreadRadius: spread2),
              ],
            ),
            child: ClipOval(
              child: Stack(alignment: Alignment.center, children: [
                // top specular
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 46,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x8CFFFFFF),
                          Color(0x33FFFFFF),
                          Colors.transparent
                        ],
                        stops: [0, 0.45, 1],
                      ),
                    ),
                  ),
                ),
                // bottom glint
                Positioned(
                  bottom: 7,
                  left: 18,
                  right: 18,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.10),
                          Colors.transparent
                        ],
                      ),
                    ),
                  ),
                ),
                // spinning arc
                AnimatedBuilder(
                  animation: _arcCtrl,
                  builder: (_, __) => Transform.rotate(
                    angle: _arcCtrl.value * 2 * pi,
                    child: CustomPaint(
                      size: const Size(68, 68),
                      painter: _ArcPainter(),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }

  // ─── Waveform ─────────────────────────────────────────────────────────────────
  Widget _waveform() {
    const wbarHeights = [
      14.0,
      22.0,
      30.0,
      36.0,
      28.0,
      22.0,
      32.0,
      20.0,
      26.0,
      16.0,
      24.0,
      18.0
    ];
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(12, (i) {
          return AnimatedBuilder(
            animation: _wbarCtrl[i],
            builder: (_, __) {
              final scale = _lerp(1.0, 0.25, _wbarCtrl[i].value);
              final opacity = _lerp(0.8, 0.4, _wbarCtrl[i].value);
              return Padding(
                padding: EdgeInsets.only(right: i < 11 ? 5.0 : 0),
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 4,
                    height: wbarHeights[i] * scale,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color(0x99FB923C),
                          Color(0xCCF472B6),
                          Color(0x99C4B5FD)
                        ],
                        stops: [0, 0.5, 1],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  // ─── Headline ─────────────────────────────────────────────────────────────────
  Widget _headline() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'serif',
          fontSize: 30,
          fontWeight: FontWeight.w300,
          fontStyle: FontStyle.italic,
          height: 1.22,
          letterSpacing: -0.3,
          color: Color(0xF5F0F5FF),
        ),
        children: [
          const TextSpan(text: 'Analysing your\n'),
          WidgetSpan(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kOrange, kPink],
              ).createShader(bounds),
              child: const Text(
                'emotions…',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.normal,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step tile ────────────────────────────────────────────────────────────────
  Widget _stepTile(AnalysisStep step) {
    final isActive = step.state == StepState.active;
    final isDone = step.state == StepState.done;

    Color titleColor = Colors.white.withValues(alpha: 0.75);
    Color subColor = Colors.white.withValues(alpha: 0.28);
    Color statusColor = Colors.white.withValues(alpha: 0.25);
    if (isActive) {
      titleColor = Colors.white.withValues(alpha: 0.95);
      subColor = kOrange.withValues(alpha: 0.65);
      statusColor = kOrange.withValues(alpha: 0.80);
    }
    if (isDone) {
      titleColor = kGreen.withValues(alpha: 0.90);
      subColor = kGreen.withValues(alpha: 0.50);
      statusColor = kGreen.withValues(alpha: 0.80);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: const Cubic(0.22, 1, 0.36, 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? kOrange.withValues(alpha: 0.25)
                  : isDone
                      ? kGreen.withValues(alpha: 0.20)
                      : Colors.white.withValues(alpha: 0.10),
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.white.withValues(alpha: 0.08),
                  offset: const Offset(0, 1),
                  blurRadius: 0),
              BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.20),
                  blurRadius: 10,
                  offset: const Offset(0, 2)),
              if (isActive)
                BoxShadow(
                    color: kOrange.withValues(alpha: 0.10),
                    blurRadius: 16,
                    spreadRadius: 1),
              if (isDone)
                BoxShadow(
                    color: kGreen.withValues(alpha: 0.08),
                    blurRadius: 12,
                    spreadRadius: 1),
            ],
          ),
          child: Stack(children: [
            // animated fill
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 1200),
                curve: const Cubic(0.22, 1, 0.36, 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: isDone
                        ? [
                            kOrange.withValues(alpha: 0.12),
                            kPink.withValues(alpha: 0.08)
                          ]
                        : [Colors.transparent, Colors.transparent],
                  ),
                ),
              ),
            ),
            // top shine
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 22,
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x0FFFFFFF), Colors.transparent],
                  ),
                ),
              ),
            ),
            Row(children: [
              // icon wrap
              _stepIconWrap(step),
              const SizedBox(width: 12),
              // text
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: titleColor,
                            letterSpacing: 0.13),
                        child: Text(step.title),
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                            fontSize: 11, color: subColor, letterSpacing: 0.11),
                        child: Text(step.sub),
                      ),
                    ]),
              ),
              const SizedBox(width: 8),
              // spinner or status
              if (isActive)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: AnimatedBuilder(
                    animation: _arcCtrl,
                    builder: (_, __) => Transform.rotate(
                      angle: _arcCtrl.value * 2 * pi,
                      child: CustomPaint(painter: _MiniSpinnerPainter()),
                    ),
                  ),
                )
              else
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: isDone ? 14 : 11,
                    letterSpacing: 0.44,
                    color: statusColor,
                  ),
                  child: Text(isDone ? step.doneLabel : '–'),
                ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _stepIconWrap(AnalysisStep step) {
    final isActive = step.state == StepState.active;
    final isDone = step.state == StepState.done;

    Color bg = Colors.white.withValues(alpha: 0.07);
    Color border = Colors.white.withValues(alpha: 0.12);
    List<BoxShadow> shadows = [];

    if (isActive) {
      bg = kOrange.withValues(alpha: 0.16);
      border = kOrange.withValues(alpha: 0.35);
      shadows = [
        BoxShadow(color: kOrange.withValues(alpha: 0.20), blurRadius: 12)
      ];
    } else if (isDone) {
      bg = kGreen.withValues(alpha: 0.14);
      border = kGreen.withValues(alpha: 0.35);
      shadows = [
        BoxShadow(color: kGreen.withValues(alpha: 0.18), blurRadius: 10)
      ];
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: const Cubic(0.22, 1, 0.36, 1),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
        boxShadow: shadows,
      ),
      child: Center(
        child: isDone
            ? Text(step.icon, style: const TextStyle(fontSize: 16))
            : isActive
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: AnimatedBuilder(
                      animation: _arcCtrl,
                      builder: (_, __) => Transform.rotate(
                        angle: _arcCtrl.value * 2 * pi,
                        child: CustomPaint(painter: _MiniSpinnerPainter()),
                      ),
                    ),
                  )
                : Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.20),
                    ),
                  ),
      ),
    );
  }

  // ─── Hint dot ─────────────────────────────────────────────────────────────────
  Widget _hintDot(int idx) {
    return AnimatedBuilder(
      animation: _hintDotCtrl[idx],
      builder: (_, __) {
        final v = _hintDotCtrl[idx].value;
        return Transform.scale(
          scale: _lerp(0.8, 1.2, v),
          child: Opacity(
            opacity: _lerp(0.3, 1.0, v),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kOrange.withValues(alpha: 0.50),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Fade-up helper ───────────────────────────────────────────────────────────
  Widget _fadeUp(AnimationController ctrl, Widget child) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final v =
            CurvedAnimation(parent: ctrl, curve: const Cubic(0.22, 1, 0.36, 1))
                .value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
              offset: Offset(0, _lerp(16, 0, v)), child: child),
        );
      },
    );
  }
}

// ─── Cancel button ────────────────────────────────────────────────────────────
class _CancelButton extends StatefulWidget {
  final bool cancelled;
  final VoidCallback onTap;
  const _CancelButton({required this.cancelled, required this.onTap});
  @override
  State<_CancelButton> createState() => _CancelButtonState();
}

class _CancelButtonState extends State<_CancelButton> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _hover = true),
      onTapUp: (_) => setState(() => _hover = false),
      onTapCancel: () => setState(() => _hover = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _hover ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: _hover ? 0.09 : 0.05),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.white.withValues(alpha: 0.12),
                      offset: const Offset(0, 1),
                      blurRadius: 0),
                ],
              ),
              child: Stack(children: [
                // top shine
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 12,
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(100)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x1AFFFFFF), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Text(
                  widget.cancelled ? 'Cancelling…' : 'Cancel',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: _hover ? 0.65 : 0.40),
                    letterSpacing: 0.78,
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Arc painter (spinning inside core orb) ───────────────────────────────────
class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.width / 2 - 2;

    // faint full circle
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.06),
    );

    // gradient arc (quarter circle: top to right)
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: -pi / 2,
        endAngle: 0,
        colors: [Color(0x00FB923C), Color(0xF2FB923C)],
      ).createShader(rect);

    canvas.drawArc(rect, -pi / 2, pi / 2, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Mini spinner painter (for steps) ────────────────────────────────────────
class _MiniSpinnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.width / 2 - 1;

    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = kOrange.withValues(alpha: 0.20),
    );

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    canvas.drawArc(
      rect,
      -pi / 2,
      pi * 1.2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = kOrange.withValues(alpha: 0.90),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
