import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const ExitConfirmationApp());
}

// ─── Palette ──────────────────────────────────────────────────────────────────
const Color kOrange = Color(0xFFFB923C);
const Color kPink = Color(0xFFF472B6);
const Color kViolet = Color(0xFFC4B5FD);
const Color kBlue = Color(0xFF93C5FD);
const Color kGreen = Color(0xFFA7F3D0);

double _lerp(double a, double b, double t) => a + (b - a) * t;

class ExitConfirmationApp extends StatelessWidget {
  const ExitConfirmationApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoodUplift – Exit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: const Color(0xFF000000)),
      home: const ExitScreen(),
    );
  }
}

// ─── Exit Screen ──────────────────────────────────────────────────────────────
class ExitScreen extends StatefulWidget {
  const ExitScreen({super.key});
  @override
  State<ExitScreen> createState() => _ExitScreenState();
}

class _ExitScreenState extends State<ExitScreen> with TickerProviderStateMixin {
  // eyebrow dot
  late final AnimationController _dotCtrl;

  // central icon float + ring pulse
  late final AnimationController _iconFloatCtrl;
  late final AnimationController _ringPulseCtrl;
  // heartbeat on mood dot
  late final AnimationController _heartbeatCtrl;
  // session bar fill
  late final AnimationController _barCtrl;
  // yes button float
  late final AnimationController _yesBtnCtrl;
  // yes button press + state
  late final AnimationController _yesPressCtrl;
  // continue press
  late final AnimationController _continuePressCtrl;

  // entrance
  late final AnimationController _topBarCtrl;
  late final AnimationController _iconCtrl;
  late final AnimationController _headingCtrl;
  late final AnimationController _actionsCtrl;
  late final AnimationController _tipCtrl;

  // yes button label state
  bool _yesConfirmed = false;

  void _after(int ms, VoidCallback fn) =>
      Future.delayed(Duration(milliseconds: ms), () {
        if (mounted) fn();
      });

  @override
  void initState() {
    super.initState();

    _dotCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);

    _iconFloatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4000))
      ..repeat(reverse: true);
    _ringPulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat(reverse: true);
    _heartbeatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat();
    _barCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _yesBtnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3800))
      ..repeat(reverse: true);
    _yesPressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _continuePressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));

    // entrance
    _topBarCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _iconCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _headingCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _actionsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _tipCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    _after(100, _iconCtrl.forward);
    _after(180, _headingCtrl.forward);
    _after(300, () {
      _actionsCtrl.forward();
      _after(300, _barCtrl.forward);
    });
    _after(440, _tipCtrl.forward);
  }

  @override
  void dispose() {
    _dotCtrl.dispose();
    _iconFloatCtrl.dispose();
    _ringPulseCtrl.dispose();
    _heartbeatCtrl.dispose();
    _barCtrl.dispose();
    _yesBtnCtrl.dispose();
    _yesPressCtrl.dispose();
    _continuePressCtrl.dispose();
    _topBarCtrl.dispose();
    _iconCtrl.dispose();
    _headingCtrl.dispose();
    _actionsCtrl.dispose();
    _tipCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: LayoutBuilder(builder: (context, cs) {
        final W = cs.maxWidth;
        final H = cs.maxHeight;
        return Stack(children: [
          _background(W, H),
          _scrollContent(W, H),
          Positioned(bottom: 0, left: 0, right: 0, child: _tipCard()),
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

  // ─── Scroll content ───────────────────────────────────────────────────────────
  Widget _scrollContent(double W, double H) {
    return Positioned.fill(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(W * 0.067, 0, W * 0.067, 180),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 8),
            _fadeUp(_topBarCtrl, _topBar()),
            const SizedBox(height: 10),
            _scaleIn(_iconCtrl, _centralIcon()),
            const SizedBox(height: 4),
            _fadeUp(_headingCtrl, _headingBlock()),
            const SizedBox(height: 24),
            _fadeUp(_actionsCtrl, _actionButtons()),
          ]),
        ),
      ),
    );
  }

  // ─── Top bar ─────────────────────────────────────────────────────────────────
  Widget _topBar() {
    return Row(children: [
      _glassBtn('‹'),
      const Spacer(),
      Text('SEE YOU SOON',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.45),
              letterSpacing: 0.14 * 13)),
      const Spacer(),
      const SizedBox(width: 36),
    ]);
  }

  Widget _glassBtn(String icon, {double fontSize = 16}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                  color: Colors.white.withValues(alpha: 0.10),
                  offset: const Offset(0, 1),
                  blurRadius: 0)
            ],
          ),
          child: Stack(children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 18,
              child: Container(
                  decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x18FFFFFF), Colors.transparent]),
              )),
            ),
            Center(
                child: Text(icon,
                    style: TextStyle(
                        fontSize: fontSize,
                        color: Colors.white.withValues(alpha: 0.65)))),
          ]),
        ),
      ),
    );
  }

  // ─── Central icon ─────────────────────────────────────────────────────────────
  Widget _centralIcon() {
    return Center(
      child: SizedBox(
        width: 120,
        height: 120,
        child: AnimatedBuilder(
          animation: Listenable.merge([_ringPulseCtrl, _iconFloatCtrl]),
          builder: (_, __) {
            final ring = _ringPulseCtrl.value;
            final floatY = _lerp(0, -8, _iconFloatCtrl.value);
            return Stack(alignment: Alignment.center, children: [
              // outer pulsing ring
              Opacity(
                opacity: _lerp(0.45, 0, ring),
                child: Transform.scale(
                  scale: _lerp(1.0, 1.06, ring),
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: kOrange.withValues(alpha: 0.16), width: 1),
                    ),
                  ),
                ),
              ),
              // floating inner icon
              Transform.translate(
                offset: Offset(0, floatY),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(41),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              kOrange.withValues(alpha: 0.20),
                              kPink.withValues(alpha: 0.16)
                            ]),
                        border:
                            Border.all(color: Colors.white.withValues(alpha: 0.16)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.white.withValues(alpha: 0.22),
                              offset: const Offset(0, 2),
                              blurRadius: 0),
                          BoxShadow(
                              color: kOrange.withValues(alpha: 0.18), blurRadius: 40),
                          BoxShadow(
                              color: kPink.withValues(alpha: 0.10), blurRadius: 80),
                        ],
                      ),
                      child: Stack(children: [
                        Positioned.fill(
                            child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.22),
                                  Colors.transparent
                                ]),
                          ),
                        )),
                        const Center(
                            child: Text('🎧', style: TextStyle(fontSize: 34))),
                      ]),
                    ),
                  ),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  // ─── Heading block ────────────────────────────────────────────────────────────
  Widget _headingBlock() {
    return Column(children: [
      // eyebrow
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedBuilder(
            animation: _dotCtrl,
            builder: (_, __) {
              final v = _dotCtrl.value;
              return Opacity(
                opacity: _lerp(1.0, 0.35, v),
                child: Transform.scale(
                  scale: _lerp(1.0, 0.55, v),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kOrange.withValues(alpha: 0.70),
                        boxShadow: [
                          BoxShadow(
                              color: kOrange.withValues(alpha: 0.70), blurRadius: 6)
                        ]),
                  ),
                ),
              );
            }),
        const SizedBox(width: 6),
        Text('A MOMENT OF REFLECTION',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.18 * 11,
                color: kOrange.withValues(alpha: 0.70))),
      ]),
      const SizedBox(height: 10),
      // main heading
      RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 30,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
                color: Color(0xFFF0F0FF),
                height: 1.28),
            children: [
              const TextSpan(text: 'Do you feel\n'),
              WidgetSpan(
                  child: ShaderMask(
                shaderCallback: (b) =>
                    const LinearGradient(colors: [kOrange, kPink])
                        .createShader(b),
                child: const Text('better now?',
                    style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.normal,
                        color: Colors.white)),
              )),
            ],
          )),
      const SizedBox(height: 10),
      // sub
      Text(
          'Hope the music helped lift your spirit\nand brought a little calm to your day.',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.42),
              height: 1.6,
              letterSpacing: 0.01 * 13)),
    ]);
  }

  // ─── Action buttons ───────────────────────────────────────────────────────────
  Widget _actionButtons() {
    return Column(children: [
      _yesBetterButton(),
      const SizedBox(height: 12),
      _continueButton(),
    ]);
  }

  // Primary — Yes, I feel better
  Widget _yesBetterButton() {
    return AnimatedBuilder(
      animation: Listenable.merge([_yesBtnCtrl, _yesPressCtrl]),
      builder: (_, __) {
        final float = _lerp(0, -5, _yesBtnCtrl.value);
        final press =
            CurvedAnimation(parent: _yesPressCtrl, curve: Curves.easeOut).value;
        return Transform.translate(
          offset: Offset(0, float),
          child: Stack(children: [
            // pulsing ring
            Opacity(
              opacity: _lerp(0.45, 0, _ringPulseCtrl.value),
              child: Transform.scale(
                scale: _lerp(1.0, 1.06, _ringPulseCtrl.value),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(21),
                    border:
                        Border.all(color: kGreen.withValues(alpha: 0.20), width: 1),
                  ),
                ),
              ),
            ),
            // button
            GestureDetector(
              onTapDown: (_) => _yesPressCtrl.forward(),
              onTapUp: (_) {
                _yesPressCtrl.reverse();
                if (!_yesConfirmed) {
                  setState(() => _yesConfirmed = true);
                  _after(2400, () {
                    if (mounted) setState(() => _yesConfirmed = false);
                  });
                }
              },
              onTapCancel: () => _yesPressCtrl.reverse(),
              child: Transform.scale(
                scale: _lerp(1.0, 0.97, press),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _yesConfirmed
                                ? [
                                    kGreen.withValues(alpha: 0.38),
                                    kBlue.withValues(alpha: 0.30)
                                  ]
                                : [
                                    Color.lerp(kGreen.withValues(alpha: 0.28),
                                        kGreen.withValues(alpha: 0.48), press)!,
                                    Color.lerp(kBlue.withValues(alpha: 0.22),
                                        kBlue.withValues(alpha: 0.38), press)!,
                                  ]),
                        border: Border.all(
                            color:
                                kGreen.withValues(alpha: _lerp(0.42, 0.80, press))),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.white.withValues(alpha: 0.40),
                              offset: const Offset(0, 1),
                              blurRadius: 0),
                          BoxShadow(
                              color: kGreen.withValues(alpha: _yesConfirmed
                                  ? 0.26
                                  : _lerp(0.14, 0.40, press)),
                              blurRadius:
                                  _yesConfirmed ? 40 : _lerp(32, 48, press),
                              offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Stack(children: [
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
                                  Color(0x33FFFFFF),
                                  Colors.transparent
                                ]),
                          )),
                        ),
                        Center(
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(_yesConfirmed ? '🌟' : '✦',
                              style: TextStyle(
                                  fontSize: _lerp(18, 20, press),
                                  color: Colors.white)),
                          const SizedBox(width: 10),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Text(
                              _yesConfirmed
                                  ? 'So glad to hear that! 🌟'
                                  : 'Yes, I feel better · Exit',
                              key: ValueKey(_yesConfirmed),
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.03 * 14),
                            ),
                          ),
                        ])),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  // Secondary — Continue Listening
  Widget _continueButton() {
    return AnimatedBuilder(
        animation: _continuePressCtrl,
        builder: (_, __) {
          final press =
              CurvedAnimation(parent: _continuePressCtrl, curve: Curves.easeOut)
                  .value;
          return GestureDetector(
            onTapDown: (_) => _continuePressCtrl.forward(),
            onTapUp: (_) => _continuePressCtrl.reverse(),
            onTapCancel: () => _continuePressCtrl.reverse(),
            child: Transform.scale(
              scale: _lerp(1.0, 0.97, press),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.white.withValues(alpha: _lerp(0.06, 0.11, press)),
                      border: Border.all(
                          color: Colors.white
                              .withValues(alpha: _lerp(0.14, 0.26, press))),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.white.withValues(alpha: 0.10),
                            offset: const Offset(0, 2),
                            blurRadius: 0),
                        BoxShadow(
                            color: const Color(0xFF000000).withValues(alpha: 0.20),
                            blurRadius: _lerp(18, 26, press),
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Stack(children: [
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
                              colors: [Color(0x1AFFFFFF), Colors.transparent]),
                        )),
                      ),
                      Center(
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Text('🎶', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Text('Continue Listening',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white
                                    .withValues(alpha: _lerp(0.72, 0.92, press)),
                                letterSpacing: 0.02 * 14)),
                      ])),
                    ]),
                  ),
                ),
              ),
            ),
          );
        });
  }

  // ─── Tip card ─────────────────────────────────────────────────────────────────
  Widget _tipCard() {
    return AnimatedBuilder(
        animation: _tipCtrl,
        builder: (_, __) {
          final v = CurvedAnimation(
                  parent: _tipCtrl, curve: const Cubic(0.22, 1, 0.36, 1))
              .value;
          return Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, _lerp(14, 0, v)),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xEB0A0A16), Colors.transparent],
                    stops: [0.6, 1.0],
                  ),
                ),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: RichText(
                              text: TextSpan(
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.38),
                            height: 1.55),
                        children: [
                          TextSpan(
                              text: 'Tip: ',
                              style: TextStyle(
                                  color: kOrange.withValues(alpha: 0.65),
                                  fontWeight: FontWeight.w500)),
                          const TextSpan(
                              text:
                                  'Regular mood check-ins help our AI learn your emotional patterns and craft an even more personalised music journey for you.'),
                        ],
                      ))),
                    ]),
              ),
            ),
          );
        });
  }

  // ─── Fade-up helper ───────────────────────────────────────────────────────────
  Widget _fadeUp(AnimationController ctrl, Widget child) {
    return AnimatedBuilder(
        animation: ctrl,
        builder: (_, __) {
          final v = CurvedAnimation(
                  parent: ctrl, curve: const Cubic(0.22, 1, 0.36, 1))
              .value;
          return Opacity(
              opacity: v,
              child: Transform.translate(
                  offset: Offset(0, _lerp(14, 0, v)), child: child));
        });
  }

  // ─── Scale-in helper (for central icon) ──────────────────────────────────────
  Widget _scaleIn(AnimationController ctrl, Widget child) {
    return AnimatedBuilder(
        animation: ctrl,
        builder: (_, __) {
          final v = CurvedAnimation(
                  parent: ctrl, curve: const Cubic(0.22, 1, 0.36, 1))
              .value;
          return Opacity(
              opacity: v,
              child: Transform.scale(
                  scale: _lerp(0.88, 1.0, v),
                  child: Transform.translate(
                      offset: Offset(0, _lerp(10, 0, v)), child: child)));
        });
  }
}
