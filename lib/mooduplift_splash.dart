import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'mood_input.dart';
import 'mooduplift_login.dart';
import 'mooduplift_create_account.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Make the status bar and navigation bar fully transparent
  // so the app feels truly immersive
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const MoodUpliftApp());
}

// ─── Color palette ────────────────────────────────────────────────────────────
const Color kBg = Color(0xFF000000);
const Color kBlue = Color(0xFF93C5FD); // rgba(147,197,253)
const Color kPurple = Color(0xFFC4B5FD); // rgba(196,181,253)
const Color kGreen = Color(0xFFA7F3D0); // rgba(167,243,208)

double _lerp(double a, double b, double t) => a + (b - a) * t;

// ─── App root ─────────────────────────────────────────────────────────────────
class MoodUpliftApp extends StatelessWidget {
  const MoodUpliftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Mood Uplift',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: kBg,
        colorScheme: const ColorScheme.dark(),
      ),
      home: const SplashScreen(),
    );
  }
}

// ─── Splash Screen ────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // entrance animations
  late final AnimationController _contentCtrl;
  late final AnimationController _quoteCtrl;
  late final AnimationController _markCtrl;
  late final AnimationController _pillsCtrl;
  late final AnimationController _bottomCtrl;

  @override
  void initState() {
    super.initState();

    // ── entrance ──
    _contentCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..forward();

    _quoteCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    _after(300, _quoteCtrl.forward);

    _markCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _after(500, _markCtrl.forward);

    _pillsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _after(600, _pillsCtrl.forward);

    _bottomCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _after(800, _bottomCtrl.forward);
  }

  void _after(int ms, VoidCallback fn) {
    Future.delayed(Duration(milliseconds: ms), () {
      if (mounted) fn();
    });
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _quoteCtrl.dispose();
    _markCtrl.dispose();
    _pillsCtrl.dispose();
    _bottomCtrl.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder so the wave / orbs / notes scale to the real screen
    return Scaffold(
      backgroundColor: kBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final W = constraints.maxWidth;
          final H = constraints.maxHeight;
          return Stack(
            children: [
              // ── Background ──────────────────────────────────────────────────
              _backgroundGradient(W, H),
              // ── Main content ────────────────────────────────────────────────
              _mainContent(W, H),
            ],
          );
        },
      ),
    );
  }

  // ─── Background ──────────────────────────────────────────────────────────────
  Widget _backgroundGradient(double W, double H) {
    return const Positioned.fill(
      child: ColoredBox(color: Color(0xFF000000)),
    );
  }

  // ─── Main content ─────────────────────────────────────────────────────────────
  Widget _mainContent(double W, double H) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _contentCtrl,
        builder: (_, __) {
          final v = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut)
              .value;
          return Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, _lerp(20, 0, v)),
              child: SafeArea(
                child: Padding(
                  // Generous side padding; top/bottom via SafeArea + extra
                  padding: EdgeInsets.fromLTRB(
                    W * 0.09,
                    H * 0.02,
                    W * 0.09,
                    H * 0.04,
                  ),
                  child: Column(
                    children: [
                      _topSection(),
                      const Spacer(),
                      _quoteSection(),
                      const Spacer(),
                      _bottomSection(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── TOP: logo + app name ─────────────────────────────────────────────────────
  Widget _topSection() {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return Column(
          children: [
            _logoMark(),
            const SizedBox(height: 16),
            Text(
              appState.appName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 2.86,
                color: kBlue.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              appState.tagline,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.25),
                letterSpacing: 0.88,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _logoMark() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBlue.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(color: kBlue.withValues(alpha: 0.08), spreadRadius: 1),
          BoxShadow(
            color: kBlue.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(child: _barsDance()),
    );
  }

  Widget _barsDance() {
    const heights = [14.0, 22.0, 18.0, 26.0, 12.0];
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(5, (i) {
        return Container(
          margin: EdgeInsets.only(right: i < 4 ? 3.0 : 0.0),
          width: 4,
          height: heights[i],
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xE693C5FD), Color(0xE6C4B5FD)],
            ),
          ),
        );
      }),
    );
  }

  // ─── QUOTE SECTION ────────────────────────────────────────────────────────────
  Widget _quoteSection() {
    return AnimatedBuilder(
      animation: _quoteCtrl,
      builder: (_, __) {
        final v =
            CurvedAnimation(parent: _quoteCtrl, curve: Curves.easeOut).value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, _lerp(28, 0, v)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Opening quote mark
                AnimatedBuilder(
                  animation: _markCtrl,
                  builder: (_, __) => Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Opacity(
                        opacity: _markCtrl.value,
                        child: Text(
                          '\u201C',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 72,
                            height: 0.5,
                            color: kBlue.withValues(alpha: 0.18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Quote body
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                      fontStyle: FontStyle.italic,
                      height: 1.45,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                    children: [
                      const TextSpan(text: 'Where words fail,\n'),
                      TextSpan(
                        text: 'music speaks.',
                        style: TextStyle(
                          fontStyle: FontStyle.normal,
                          fontWeight: FontWeight.w600,
                          color: kPurple.withValues(alpha: 0.95),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Divider
                Container(
                  width: 40,
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      kBlue.withValues(alpha: 0.4),
                      Colors.transparent,
                    ]),
                  ),
                ),
                const SizedBox(height: 18),
                // Author
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 20,
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.18)),
                    const SizedBox(width: 8),
                    Text(
                      'Hans Christian Andersen',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.35),
                        letterSpacing: 1.68,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                        width: 20,
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.18)),
                  ],
                ),
                const SizedBox(height: 32),
                // Mood pills
                AnimatedBuilder(
                  animation: _pillsCtrl,
                  builder: (_, __) {
                    final pv = CurvedAnimation(
                            parent: _pillsCtrl, curve: Curves.easeOut)
                        .value;
                    return Opacity(
                      opacity: pv,
                      child: Transform.translate(
                        offset: Offset(0, _lerp(14, 0, pv)),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _pill('😌  Calm', kBlue, const Color(0x5C1E3C78),
                                const Color(0xF2BEDCFF)),
                            _pill('💜  Heal', kPurple, const Color(0x5C50328C),
                                const Color(0xF2DCD2FF)),
                            _pill('✨  Uplift', kGreen, const Color(0x5C1E5A46),
                                const Color(0xF2B4FADC)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _pill(String label, Color accent, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
              color: Colors.white.withValues(alpha: 0.32),
              offset: const Offset(0, 1),
              blurRadius: 0),
          BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.18),
              offset: const Offset(0, -1),
              blurRadius: 0),
          // colored glow
          BoxShadow(
              color: accent.withValues(alpha: 0.28),
              blurRadius: 14,
              spreadRadius: 0,
              offset: const Offset(0, 2)),
          BoxShadow(
              color: accent.withValues(alpha: 0.12),
              blurRadius: 28,
              spreadRadius: 2),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.44,
          color: textColor,
        ),
      ),
    );
  }

  // ─── BOTTOM: CTA + sign-in + dots ────────────────────────────────────────────
  Widget _bottomSection() {
    return AnimatedBuilder(
      animation: _bottomCtrl,
      builder: (_, __) {
        final bv =
            CurvedAnimation(parent: _bottomCtrl, curve: Curves.easeOut).value;
        return Opacity(
          opacity: bv,
          child: Transform.translate(
            offset: Offset(0, _lerp(20, 0, bv)),
            child: Column(
              children: [
                _ctaWithRing(),
                const SizedBox(height: 16),
                _signInLink(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _ctaWithRing() {
    return const _CtaButton();
  }

  Widget _signInLink() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                  color: Colors.white.withValues(alpha: 0.14),
                  offset: const Offset(0, 1),
                  blurRadius: 0),
              BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.15),
                  offset: const Offset(0, -1),
                  blurRadius: 0),
              BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4)),
              // purple glow
              BoxShadow(
                  color: const Color(0xFFC4B5FD).withValues(alpha: 0.14),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 3)),
              BoxShadow(
                  color: const Color(0xFFC4B5FD).withValues(alpha: 0.07),
                  blurRadius: 36,
                  spreadRadius: 2),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.70),
                        letterSpacing: 0.26,
                      ),
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Sign in',
                          style: TextStyle(
                            color: kPurple.withValues(alpha: 0.90),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── CTA button ───────────────────────────────────────────────────────────────
class _CtaButton extends StatefulWidget {
  const _CtaButton();
  @override
  State<_CtaButton> createState() => _CtaButtonState();
}

class _CtaButtonState extends State<_CtaButton> {
  bool _pressed = false;

  void _onTap(BuildContext context) {
    // Check if already logged in → skip to MoodInput
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MoodInputScreen()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => _onTap(context),
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _pressed ? 0.11 : 0.16),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.38)),
            boxShadow: [
              BoxShadow(
                  color: Colors.white.withValues(alpha: 0.46),
                  offset: const Offset(0, 1),
                  blurRadius: 0),
              BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.26),
                  offset: const Offset(0, -1),
                  blurRadius: 0),
              BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.42),
                  blurRadius: 36,
                  offset: const Offset(0, 8)),
              // blue-white glow
              BoxShadow(
                  color: const Color(0xFF93C5FD).withValues(alpha: 0.18),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 4)),
              BoxShadow(
                  color: Colors.white.withValues(alpha: 0.08),
                  blurRadius: 40,
                  spreadRadius: 2),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(children: [
              // Top specular shine
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 27,
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(18)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x80FFFFFF),
                        Color(0x33FFFFFF),
                        Color(0x0DFFFFFF),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.36, 0.68, 1.0],
                    ),
                  ),
                ),
              ),
              // Bottom dark rim
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 21,
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(18)),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0x3D000000),
                        Color(0x0F000000),
                        Colors.transparent
                      ],
                      stops: [0.0, 0.60, 1.0],
                    ),
                  ),
                ),
              ),
              // Label + arrow
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Begin Your Journey',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.98),
                        letterSpacing: 0.48,
                        shadows: [
                          Shadow(
                              color: const Color(0xFF000000)
                                  .withValues(alpha: 0.55),
                              blurRadius: 4,
                              offset: const Offset(0, 1))
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _arrowBubble(),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _arrowBubble() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.36)),
        boxShadow: [
          BoxShadow(
              color: Colors.white.withValues(alpha: 0.44),
              offset: const Offset(0, 1),
              blurRadius: 0),
          BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.18),
              offset: const Offset(0, -1),
              blurRadius: 0),
          BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.30),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Center(
        child: Text(
          '→',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white,
            shadows: [
              Shadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.40),
                  blurRadius: 2,
                  offset: const Offset(0, 1))
            ],
          ),
        ),
      ),
    );
  }
}
