import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'mood_input.dart';
import 'mooduplift_create_account.dart';

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
const Color kBg = Color(0xFF000000);
const Color kBlue = Color(0xFF93C5FD);
const Color kPurple = Color(0xFFC4B5FD);
const Color kGreen = Color(0xFFA7F3D0);

double _lerp(double a, double b, double t) => a + (b - a) * t;

// ─── App root ─────────────────────────────────────────────────────────────────
class MoodUpliftApp extends StatelessWidget {
  const MoodUpliftApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return MaterialApp(
          title: 'AI Mood Uplift',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(scaffoldBackgroundColor: kBg),
          home: appState.isLoggedIn
              ? const MoodInputScreen()
              : const LoginScreen(),
        );
      },
    );
  }
}

// ─── Login Screen ─────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // entrance
  late final AnimationController _pageCtrl;
  late final AnimationController _logoCtrl;
  late final AnimationController _headCtrl;
  late final AnimationController _formCtrl;
  late final AnimationController _btnCtrl;
  late final AnimationController _bioCtrl;
  late final AnimationController _signupCtrl;

  // form state
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  bool _obscurePass = true;
  bool _emailFocused = false;
  bool _passFocused = false;
  bool _loggingIn = false;

  void _after(int ms, VoidCallback fn) =>
      Future.delayed(Duration(milliseconds: ms), () {
        if (mounted) fn();
      });

  @override
  void initState() {
    super.initState();

    // ── entrance animations ──
    _pageCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _headCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _formCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _btnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _bioCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _signupCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    _after(100, _logoCtrl.forward);
    _after(200, _headCtrl.forward);
    _after(300, _formCtrl.forward);
    _after(500, _btnCtrl.forward);
    _after(550, _bioCtrl.forward);
    _after(600, _signupCtrl.forward);

    // focus listeners
    _emailFocus.addListener(
        () => setState(() => _emailFocused = _emailFocus.hasFocus));
    _passFocus
        .addListener(() => setState(() => _passFocused = _passFocus.hasFocus));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _logoCtrl.dispose();
    _headCtrl.dispose();
    _formCtrl.dispose();
    _btnCtrl.dispose();
    _bioCtrl.dispose();
    _signupCtrl.dispose();

    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password.')),
      );
      return;
    }
    setState(() => _loggingIn = true);
    final appState = Provider.of<AppState>(context, listen: false);

    try {
      await appState.login(email, password);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MoodInputScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loggingIn = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(builder: (context, constraints) {
        final W = constraints.maxWidth;
        final H = constraints.maxHeight;
        return Stack(children: [
          _background(W, H),
          // scrollable content
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

  // ─── Content ─────────────────────────────────────────────────────────────────
  Widget _content(double W, double H) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _pageCtrl,
        builder: (_, __) {
          final v =
              CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut).value;
          return Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, _lerp(16, 0, v)),
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                      W * 0.072, H * 0.016, W * 0.072, H * 0.18),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _logoArea(),
                        _headingBlock(),
                        _formFields(),
                        _forgotPassword(),
                        const SizedBox(height: 20),
                        _loginButton(),
                        const SizedBox(height: 22),
                        _signupRow(),
                      ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Logo area ───────────────────────────────────────────────────────────────
  Widget _logoArea() {
    return _staggered(
      ctrl: _logoCtrl,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 28),
        child: Column(children: [
          _logoMark(),
          const SizedBox(height: 10),
          Text(
            context.watch<AppState>().appName.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.22 * 11,
              color: kBlue.withValues(alpha: 0.65),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _logoMark() {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(
              color: Colors.white.withValues(alpha: 0.44),
              offset: const Offset(0, 1),
              blurRadius: 0),
          BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.22),
              offset: const Offset(0, -1),
              blurRadius: 0),
          BoxShadow(
            color: kBlue.withValues(alpha: 0.26),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(children: [
          // top specular
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 32,
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x75FFFFFF),
                    Color(0x29FFFFFF),
                    Colors.transparent
                  ],
                  stops: [0, 0.42, 1],
                ),
              ),
            ),
          ),
          Center(child: _barsDance()),
        ]),
      ),
    );
  }

  Widget _barsDance() {
    const heights = [12.0, 20.0, 15.0, 22.0, 10.0];
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(5, (i) {
        return Container(
          margin: EdgeInsets.only(right: i < 4 ? 3.0 : 0),
          width: 3.5,
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

  // ─── Heading ─────────────────────────────────────────────────────────────────
  Widget _headingBlock() {
    return _staggered(
      ctrl: _headCtrl,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 30,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                height: 1.2,
                color: Colors.white.withValues(alpha: 0.95),
              ),
              children: [
                const TextSpan(text: 'Welcome '),
                TextSpan(
                  text: 'back',
                  style: TextStyle(
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.w600,
                    color: kPurple.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in to continue your healing journey',
            style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.38),
                fontWeight: FontWeight.w400),
          ),
        ]),
      ),
    );
  }

  // ─── Form fields ─────────────────────────────────────────────────────────────
  Widget _formFields() {
    return _staggered(
      ctrl: _formCtrl,
      child: Column(children: [
        _inputField(
          label: 'Email',
          hint: 'you@example.com',
          icon: '✉️',
          controller: _emailCtrl,
          focusNode: _emailFocus,
          focused: _emailFocused,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _inputField(
          label: 'Password',
          hint: 'Enter your password',
          icon: _obscurePass ? '👁️' : '🙈',
          controller: _passCtrl,
          focusNode: _passFocus,
          focused: _passFocused,
          obscure: _obscurePass,
          onIconTap: () => setState(() => _obscurePass = !_obscurePass),
        ),
      ]),
    );
  }

  Widget _inputField({
    required String label,
    required String hint,
    required String icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool focused,
    bool obscure = false,
    TextInputType? keyboardType,
    VoidCallback? onIconTap,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.40),
            letterSpacing: 0.10 * 11,
          ),
        ),
      ),
      AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.20),
                blurRadius: 16,
                offset: const Offset(0, 4)),
            if (focused)
              BoxShadow(
                  color: kPurple.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 1),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: focused ? 0.10 : 0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: focused
                      ? kPurple.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.14),
                ),
              ),
              child: Stack(children: [
                // top shine
                Positioned(
                  top: 1,
                  left: 2,
                  right: 2,
                  height: 20,
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(15)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x17FFFFFF), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 48),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    obscureText: obscure,
                    keyboardType: keyboardType,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.90),
                      letterSpacing: 0.01 * 14,
                    ),
                    cursorColor: kPurple.withValues(alpha: 0.9),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.22),
                          fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 0,
                  top: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: onIconTap,
                      child: Text(
                        icon,
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(
                                alpha: onIconTap != null ? 0.50 : 0.35)),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }

  // ─── Forgot password ─────────────────────────────────────────────────────────
  Widget _forgotPassword() {
    return _staggered(
      ctrl: _formCtrl,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1A2E),
                  title: const Text('Forgot Password',
                      style: TextStyle(color: Colors.white)),
                  content: const Text(
                    'Password reset is not available in this demo. Please create a new account.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('OK',
                          style: TextStyle(color: Color(0xFFC4B5FD))),
                    ),
                  ],
                ),
              );
            },
            child: Text(
              'Forgot password?',
              style: TextStyle(
                  fontSize: 12,
                  color: kPurple.withValues(alpha: 0.55),
                  letterSpacing: 0.24),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Login button ─────────────────────────────────────────────────────────────
  Widget _loginButton() {
    return _staggered(
      ctrl: _btnCtrl,
      child: _LoginButton(
        loggingIn: _loggingIn,
        onTap: _handleLogin,
      ),
    );
  }

  // ─── Sign-up row ─────────────────────────────────────────────────────────────
  Widget _signupRow() {
    return _staggered(
      ctrl: _signupCtrl,
      child: Center(
        child: RichText(
          text: TextSpan(
            style: TextStyle(
                fontSize: 13, color: Colors.white.withValues(alpha: 0.32)),
            children: [
              TextSpan(text: 'New to ${context.read<AppState>().appName}?'),
              WidgetSpan(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const CreateAccountScreen()),
                    );
                  },
                  child: Text(
                    '  Create account',
                    style: TextStyle(
                      fontSize: 13,
                      color: kPurple.withValues(alpha: 0.80),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Stagger helper ──────────────────────────────────────────────────────────
  Widget _staggered(
      {required AnimationController ctrl, required Widget child}) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final v = CurvedAnimation(parent: ctrl, curve: Curves.easeOut).value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
              offset: Offset(0, _lerp(12, 0, v)), child: child),
        );
      },
    );
  }
}

// ─── Login button (stateful press) ───────────────────────────────────────────
class _LoginButton extends StatefulWidget {
  final bool loggingIn;
  final VoidCallback onTap;
  const _LoginButton({required this.loggingIn, required this.onTap});
  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _pressed ? 0.11 : 0.16),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.36)),
            boxShadow: [
              BoxShadow(
                  color: Colors.white.withValues(alpha: 0.44),
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
                  color: kBlue.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 4)),
              BoxShadow(
                  color: Colors.white.withValues(alpha: 0.08),
                  blurRadius: 40,
                  spreadRadius: 2),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(children: [
              // top specular
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 26,
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x80FFFFFF),
                        Color(0x33FFFFFF),
                        Color(0x0DFFFFFF),
                        Colors.transparent
                      ],
                      stops: [0, 0.38, 0.70, 1],
                    ),
                  ),
                ),
              ),
              // bottom dark rim
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 20,
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(16)),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0x3D000000),
                        Color(0x0F000000),
                        Colors.transparent
                      ],
                      stops: [0, 0.60, 1],
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                    widget.loggingIn ? 'Logging in…' : 'Log In',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.98),
                      letterSpacing: 0.42,
                      shadows: [
                        Shadow(
                            color:
                                const Color(0xFF000000).withValues(alpha: 0.55),
                            blurRadius: 4,
                            offset: const Offset(0, 1))
                      ],
                    ),
                  ),
                  if (!widget.loggingIn) ...[
                    const SizedBox(width: 10),
                    _arrowBubble(),
                  ],
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _arrowBubble() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
              color: Colors.white.withValues(alpha: 0.18),
              offset: const Offset(0, 1),
              blurRadius: 0),
          BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Center(
          child: Text(
        '→',
        style: TextStyle(fontSize: 13, color: Colors.white, shadows: [
          Shadow(
              color: const Color(0xFF000000).withValues(alpha: 0.40),
              blurRadius: 2)
        ]),
      )),
    );
  }
}

// ─── Reusable glass button ────────────────────────────────────────────────────
class _GlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _GlassButton({
    required this.child,
    required this.onTap,
  });

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    const double br = 16.0;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(br),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 44, sigmaY: 44),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: _pressed ? 0.20 : 0.14),
                borderRadius: BorderRadius.circular(br),
                border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.white.withValues(alpha: 0.40),
                      offset: const Offset(0, 1),
                      blurRadius: 0),
                  BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.22),
                      offset: const Offset(0, -1),
                      blurRadius: 0),
                  BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.32),
                      blurRadius: 20,
                      offset: const Offset(0, 5)),
                ],
              ),
              child: Stack(children: [
                // top specular
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 22,
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(br),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x70FFFFFF),
                          Color(0x29FFFFFF),
                          Colors.transparent
                        ],
                        stops: [0, 0.42, 1],
                      ),
                    ),
                  ),
                ),
                widget.child,
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
