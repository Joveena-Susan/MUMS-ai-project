import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'mooduplift_login.dart';
import 'mood_input.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const CreateAccountApp());
}

const Color kBlue = Color(0xFF93C5FD);
const Color kViolet = Color(0xFFC4B5FD);
const Color kGreen = Color(0xFFA7F3D0);
const Color kOrange = Color(0xFFFB923C);
const Color kPink = Color(0xFFF472B6);

double _lerp(double a, double b, double t) => a + (b - a) * t;

class CreateAccountApp extends StatelessWidget {
  const CreateAccountApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoodUplift – Create Account',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: const Color(0xFF000000)),
      home: const CreateAccountScreen(),
    );
  }
}

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});
  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen>
    with TickerProviderStateMixin {
  late final AnimationController _topBarCtrl;
  late final AnimationController _headCtrl;
  late final AnimationController _formCtrl;
  late final AnimationController _btnCtrl;
  late final AnimationController _pressCtrl;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();

  bool _passVisible = false;
  bool _confirmVisible = false;
  int _passStrength = 0;
  int? _selectedGender;

  bool _creating = false;
  bool _created = false;

  void _after(int ms, VoidCallback fn) =>
      Future.delayed(Duration(milliseconds: ms), () {
        if (mounted) fn();
      });

  @override
  void initState() {
    super.initState();

    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 160));

    _topBarCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _headCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _formCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _btnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _after(80, _headCtrl.forward);
    _after(160, _formCtrl.forward);
    _after(380, _btnCtrl.forward);

    _passCtrl.addListener(() {
      setState(() => _passStrength = _calcStrength(_passCtrl.text));
    });
  }

  int _calcStrength(String v) {
    if (v.isEmpty) return 0;
    int s = 0;
    if (v.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(v)) s++;
    if (RegExp(r'[0-9]').hasMatch(v)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(v)) s++;
    return s;
  }

  void _calcAge() {
    final text = _dobCtrl.text;
    if (text.isEmpty) return;
    try {
      final dob = DateTime.parse(text);
      final today = DateTime.now();
      int age = today.year - dob.year;
      if (today.month < dob.month ||
          (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
      if (age > 0 && age < 130) _ageCtrl.text = age.toString();
    } catch (_) {}
  }

  void _handleCreate() async {
    if (_creating) return;
    // ── Validation ──
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields.')));
      return;
    }
    if (!RegExp(r'^[\w\-\.]+@[\w\-\.]+\.[a-zA-Z]{2,}').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email address.')));
      return;
    }
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password must be at least 6 characters.')));
      return;
    }
    if (pass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match.')));
      return;
    }
    setState(() {
      _creating = true;
      _created = false;
    });
    _pressCtrl.forward();
    _after(160, _pressCtrl.reverse);
    final appState = Provider.of<AppState>(context, listen: false);
    final genderText = _selectedGender != null
        ? ['Male', 'Female', 'Non-binary', 'Prefer not'][_selectedGender!]
        : '';

    try {
      await appState.register(
        name: name,
        email: email,
        password: pass,
        dob: _dobCtrl.text,
        age: _ageCtrl.text,
        gender: genderText,
      );
      if (!mounted) return;
      setState(() {
        _creating = false;
        _created = true;
      });
      _after(1200, () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MoodInputScreen()),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _creating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    _topBarCtrl.dispose();
    _headCtrl.dispose();
    _formCtrl.dispose();
    _btnCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _dobCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(builder: (context, cs) {
        final W = cs.maxWidth;
        return Stack(children: [
          _background(),
          _scrollContent(W),
        ]);
      }),
    );
  }

  Widget _background() => Positioned.fill(
          child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            transform: GradientRotation(160 * pi / 180),
            colors: [
              Color(0xFF0F1628),
              Color(0xFF111828),
              Color(0xFF0E1420),
              Color(0xFF12101E)
            ],
            stops: [0, 0.4, 0.7, 1],
          ),
        ),
      ));

  Widget _scrollContent(double W) {
    return Positioned.fill(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(W * 0.072, 0, W * 0.072, 140),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            _fadeUp(_topBarCtrl, _topBar(W)),
            const SizedBox(height: 20),
            _fadeUp(_headCtrl, _headingBlock()),
            const SizedBox(height: 20),
            _fadeUp(_formCtrl, _formBlock()),
            const SizedBox(height: 14),
            _fadeUp(_btnCtrl, _termsNote()),
            const SizedBox(height: 14),
            _fadeUp(_btnCtrl, _createButton()),
            const SizedBox(height: 14),
            _fadeUp(_btnCtrl, _loginRow()),
          ]),
        ),
      ),
    );
  }

  Widget _topBar(double W) {
    return Row(children: [
      const SizedBox(width: 34), // Placeholder for removed back button
      Expanded(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 44, sigmaY: 44),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: Colors.white.withValues(alpha: 0.14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.white.withValues(alpha: 0.44),
                      offset: const Offset(0, 1),
                      blurRadius: 0),
                  BoxShadow(
                      color: kBlue.withValues(alpha: 0.20), blurRadius: 32),
                ],
              ),
              child: Stack(children: [
                Positioned.fill(
                    child: Container(
                        decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.46),
                        Colors.white.withValues(alpha: 0.16),
                        Colors.transparent
                      ],
                      stops: const [
                        0,
                        0.42,
                        1
                      ]),
                ))),
                Center(
                    child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(5, (i) {
                    const heights = [7.0, 12.0, 9.0, 14.0, 6.0];
                    return Container(
                      width: 2.5,
                      height: heights[i],
                      margin: const EdgeInsets.symmetric(horizontal: 0.8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              kBlue.withValues(alpha: 0.9),
                              kViolet.withValues(alpha: 0.9)
                            ]),
                      ),
                    );
                  }),
                )),
              ]),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(context.watch<AppState>().appName.toUpperCase(),
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.22 * 10,
                color: kBlue.withValues(alpha: 0.65))),
      ])),
      const SizedBox(width: 36),
    ]);
  }

  Widget _headingBlock() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RichText(
          text: TextSpan(
        style: const TextStyle(
            fontFamily: 'serif',
            fontSize: 28,
            fontWeight: FontWeight.w300,
            fontStyle: FontStyle.italic,
            color: Color(0xFFF0F0FF),
            height: 1.22),
        children: [
          const TextSpan(text: 'Begin your '),
          WidgetSpan(
              child: ShaderMask(
            shaderCallback: (b) => LinearGradient(
                    colors: [kViolet, kViolet.withValues(alpha: 0.85)])
                .createShader(b),
            child: const Text('journey',
                style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.normal,
                    color: Colors.white)),
          )),
        ],
      )),
      const SizedBox(height: 5),
      Text('Create an account to start your healing experience',
          style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.38),
              fontWeight: FontWeight.w400)),
    ]);
  }

  Widget _formBlock() {
    return Column(children: [
      _fieldWrap(
          'Full Name', _nameCtrl, 'Your full name', '👤', TextInputType.name),
      const SizedBox(height: 13),
      _fieldWrap('Email', _emailCtrl, 'you@example.com', '✉️',
          TextInputType.emailAddress),
      const SizedBox(height: 13),
      _passwordField(),
      const SizedBox(height: 13),
      _confirmField(),
      const SizedBox(height: 13),
      _dobAgeRow(),
      const SizedBox(height: 13),
      _genderField(),
    ]);
  }

  Widget _fieldWrap(String label, TextEditingController ctrl, String hint,
      String icon, TextInputType type) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _fieldLabel(label),
      const SizedBox(height: 5),
      _inputWrap(
          child: _glassInput(
              ctrl: ctrl,
              hint: hint,
              type: type,
              suffix: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Text(icon, style: const TextStyle(fontSize: 15))))),
    ]);
  }

  Widget _passwordField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _fieldLabel('Password'),
      const SizedBox(height: 5),
      _inputWrap(
          child: _glassInput(
        ctrl: _passCtrl,
        hint: 'Create a password',
        type: TextInputType.visiblePassword,
        obscure: !_passVisible,
        suffix: GestureDetector(
            onTap: () => setState(() => _passVisible = !_passVisible),
            child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Text(_passVisible ? '🙈' : '👁️',
                    style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.35))))),
      )),
      const SizedBox(height: 6),
      _strengthBar(),
    ]);
  }

  Widget _confirmField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _fieldLabel('Confirm Password'),
      const SizedBox(height: 5),
      _inputWrap(
          child: _glassInput(
        ctrl: _confirmCtrl,
        hint: 'Re-enter your password',
        type: TextInputType.visiblePassword,
        obscure: !_confirmVisible,
        suffix: GestureDetector(
            onTap: () => setState(() => _confirmVisible = !_confirmVisible),
            child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Text(_confirmVisible ? '🙈' : '👁️',
                    style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.35))))),
      )),
    ]);
  }

  Widget _dobAgeRow() {
    return Row(children: [
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _fieldLabel('Date of Birth'),
        const SizedBox(height: 5),
        _inputWrap(
            child: _glassInput(
                ctrl: _dobCtrl,
                hint: 'YYYY-MM-DD',
                type: TextInputType.datetime,
                onChanged: (_) => _calcAge())),
      ])),
      const SizedBox(width: 10),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _fieldLabel('Age'),
        const SizedBox(height: 5),
        _inputWrap(
            child: _glassInput(
                ctrl: _ageCtrl,
                hint: '—',
                type: TextInputType.number,
                readOnly: true)),
      ])),
    ]);
  }

  Widget _genderField() {
    const genders = [
      ('♂️', 'Male'),
      ('♀️', 'Female'),
      ('⚧️', 'Non-binary'),
      ('🤍', 'Prefer not'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _fieldLabel('Gender'),
      const SizedBox(height: 5),
      Row(
          children: List.generate(genders.length, (i) {
        final isActive = _selectedGender == i;
        return Expanded(
            child: Padding(
          padding: EdgeInsets.only(right: i < genders.length - 1 ? 8 : 0),
          child: GestureDetector(
            onTap: () => setState(() => _selectedGender = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: isActive
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                            kViolet.withValues(alpha: 0.22),
                            kBlue.withValues(alpha: 0.16)
                          ])
                    : null,
                color: isActive ? null : Colors.white.withValues(alpha: 0.07),
                border: Border.all(
                    color: isActive
                        ? kViolet.withValues(alpha: 0.45)
                        : Colors.white.withValues(alpha: 0.14)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.white.withValues(alpha: 0.10),
                      offset: const Offset(0, 2),
                      blurRadius: 0),
                  if (isActive)
                    BoxShadow(
                        color: kViolet.withValues(alpha: 0.16),
                        blurRadius: 16,
                        offset: const Offset(0, 4)),
                ],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(genders[i].$1, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 3),
                Text(genders[i].$2,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isActive
                            ? kViolet.withValues(alpha: 0.98)
                            : Colors.white.withValues(alpha: 0.50))),
              ]),
            ),
          ),
        ));
      })),
    ]);
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(text,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.40),
                letterSpacing: 0.10 * 11)),
      );

  Widget _inputWrap({required Widget child}) {
    return Stack(children: [
      child,
      Positioned(
          top: 1,
          left: 2,
          right: 2,
          height: 18,
          child: Container(
              decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x17FFFFFF), Colors.transparent]),
          ))),
    ]);
  }

  Widget _glassInput({
    required TextEditingController ctrl,
    required String hint,
    required TextInputType type,
    bool obscure = false,
    bool readOnly = false,
    Widget? suffix,
    void Function(String)? onChanged,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Focus(child: Builder(builder: (ctx) {
          final focused = Focus.of(ctx).hasFocus;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withValues(alpha: focused ? 0.10 : 0.07),
              border: Border.all(
                  color: focused
                      ? kViolet.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.14)),
              boxShadow: [
                BoxShadow(
                    color: Colors.white.withValues(alpha: 0.10),
                    offset: const Offset(0, 2),
                    blurRadius: 0),
                BoxShadow(
                    color: const Color(0xFF000000).withValues(alpha: 0.20),
                    blurRadius: 16,
                    offset: const Offset(0, 4)),
                if (focused)
                  BoxShadow(
                      color: kViolet.withValues(alpha: 0.10),
                      blurRadius: 0,
                      spreadRadius: 3),
              ],
            ),
            child: TextField(
              controller: ctrl,
              keyboardType: type,
              obscureText: obscure,
              readOnly: readOnly,
              onChanged: onChanged,
              style: TextStyle(
                  fontSize: 13, color: Colors.white.withValues(alpha: 0.90)),
              cursorColor: kViolet.withValues(alpha: 0.9),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.22), fontSize: 13),
                contentPadding: const EdgeInsets.fromLTRB(16, 13, 44, 13),
                border: InputBorder.none,
                suffixIcon: suffix,
                suffixIconConstraints:
                    const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ),
          );
        })),
      ),
    );
  }

  Widget _strengthBar() {
    Color barColor(int idx) {
      if (_passCtrl.text.isEmpty || idx >= _passStrength) {
        return Colors.white.withValues(alpha: 0.08);
      }
      if (_passStrength <= 1)
        return const Color(0xFFEF4444).withValues(alpha: 0.70);
      if (_passStrength <= 2)
        return const Color(0xFFFBBF24).withValues(alpha: 0.70);
      return kGreen.withValues(alpha: 0.70);
    }

    String label = '';
    Color labelColor = Colors.transparent;
    if (_passStrength == 1) {
      label = 'Weak';
      labelColor = const Color(0xFFF87171).withValues(alpha: 0.75);
    }
    if (_passStrength == 2) {
      label = 'Fair';
      labelColor = const Color(0xFFFBBF24).withValues(alpha: 0.75);
    }
    if (_passStrength == 3) {
      label = 'Good';
      labelColor = kGreen.withValues(alpha: 0.75);
    }
    if (_passStrength == 4) {
      label = 'Strong';
      labelColor = kGreen.withValues(alpha: 0.75);
    }

    return Row(children: [
      ...List.generate(
          4,
          (i) => Expanded(
                  child: Padding(
                padding: EdgeInsets.only(right: i < 3 ? 4 : 0),
                child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 3,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: barColor(i))),
              ))),
      const SizedBox(width: 6),
      AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(label,
              key: ValueKey(label),
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: labelColor))),
    ]);
  }

  Widget _termsNote() {
    return Center(
        child: Text.rich(
      TextSpan(
        style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.20),
            height: 1.55),
        children: [
          const TextSpan(text: 'By creating an account you agree to our '),
          TextSpan(
              text: 'Terms of Service',
              style: TextStyle(color: kViolet.withValues(alpha: 0.45))),
          const TextSpan(text: ' and '),
          TextSpan(
              text: 'Privacy Policy',
              style: TextStyle(color: kViolet.withValues(alpha: 0.45))),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    ));
  }

  // ✅ FIX: Border.all() with uniform color — Flutter requires uniform border
  // colors when borderRadius is used. The subtle dark bottom rim effect is
  // preserved via the Positioned gradient overlay already present in the Stack.
  Widget _createButton() {
    return AnimatedBuilder(
      animation: _pressCtrl,
      builder: (_, __) {
        final press =
            CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut).value;
        return Stack(children: [
          // button
          GestureDetector(
            onTapDown: (_) => _pressCtrl.forward(),
            onTapUp: (_) {
              _pressCtrl.reverse();
              _handleCreate();
            },
            onTapCancel: () => _pressCtrl.reverse(),
            child: Transform.scale(
              scale: _lerp(1.0, 0.975, press),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 48, sigmaY: 48),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: _created
                          ? kGreen.withValues(alpha: 0.28)
                          : Colors.white
                              .withValues(alpha: _lerp(0.16, 0.22, press)),
                      // ✅ uniform border — no crash
                      border: Border.all(
                        color: _created
                            ? kGreen.withValues(alpha: 0.45)
                            : Colors.white.withValues(alpha: 0.36),
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.white.withValues(alpha: 0.44),
                            offset: const Offset(0, 1),
                            blurRadius: 0),
                        BoxShadow(
                            color:
                                const Color(0xFF000000).withValues(alpha: 0.42),
                            blurRadius: 36,
                            offset: const Offset(0, 8)),
                        if (_created)
                          BoxShadow(
                              color: kGreen.withValues(alpha: 0.20),
                              blurRadius: 32,
                              offset: const Offset(0, 8)),
                      ],
                    ),
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
                                stops: [
                                  0,
                                  0.38,
                                  0.70,
                                  1
                                ]),
                          ))),
                      // bottom dark rim (replaces the old dark-bottom BorderSide)
                      Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 18,
                          child: Container(
                              decoration: const BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(16)),
                            gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Color(0x3D000000),
                                  Color(0x0F000000),
                                  Colors.transparent
                                ],
                                stops: [
                                  0,
                                  0.60,
                                  1
                                ]),
                          ))),
                      // label
                      Center(
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _created
                                ? '✓ Account Created!'
                                : (_creating ? 'Creating…' : 'Create Account'),
                            key: ValueKey(_created
                                ? 'done'
                                : _creating
                                    ? 'creating'
                                    : 'idle'),
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.03 * 14),
                          ),
                        ),
                        if (!_created) ...[
                          const SizedBox(width: 10),
                          Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.16),
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.22)),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          Colors.white.withValues(alpha: 0.18),
                                      offset: const Offset(0, 1),
                                      blurRadius: 0),
                                  BoxShadow(
                                      color: const Color(0xFF000000)
                                          .withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Center(
                                  child: Text(_creating ? '…' : '→',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.white)))),
                        ],
                      ])),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ]);
      },
    );
  }

  Widget _loginRow() {
    return Center(
        child: GestureDetector(
      onTap: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      },
      child: Text.rich(
        TextSpan(
          style: TextStyle(
              fontSize: 13, color: Colors.white.withValues(alpha: 0.32)),
          children: [
            const TextSpan(text: 'Already have an account?'),
            TextSpan(
                text: ' Log in',
                style: TextStyle(
                    color: kViolet.withValues(alpha: 0.80),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ));
  }

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
}
