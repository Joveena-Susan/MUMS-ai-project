import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'app_state.dart';
import 'mooduplift_processing.dart';
import 'next_target.dart';
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
  runApp(const MoodInputApp());
}

// ─── Palette ─────────────────────────────────────────────────────────────────
const Color kOrange = Color(0xFFFB923C);
const Color kPink = Color(0xFFF472B6);
const Color kViolet = Color(0xFFC4B5FD);
const Color kBlue = Color(0xFF93C5FD);
const Color kGreen = Color(0xFFA7F3D0);
const Color kRed = Color(0xFFF87171);
const Color kYellow = Color(0xFFFBBF24);

double _lerp(double a, double b, double t) => a + (b - a) * t;

class MoodInputApp extends StatelessWidget {
  const MoodInputApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood Input',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: const Color(0xFF000000)),
      home: const MoodInputScreen(),
    );
  }
}

// ─── Chip data ────────────────────────────────────────────────────────────────
class _ChipData {
  final String label, emoji, phrase;
  final Color color;
  const _ChipData({
    required this.label,
    required this.emoji,
    required this.phrase,
    required this.color,
  });
}

const _kChips = [
  _ChipData(
    label: 'Sad',
    emoji: '😢',
    color: kBlue,
    phrase:
        "I've been feeling really sad and low lately, and I'm struggling to find joy in things I usually enjoy.",
  ),
  _ChipData(
    label: 'Stressed',
    emoji: '😤',
    color: kRed,
    phrase:
        "I'm feeling very stressed and overwhelmed right now. There's a lot on my mind and I can't seem to relax.",
  ),
  _ChipData(
    label: 'Neutral',
    emoji: '😐',
    color: kGreen,
    phrase:
        "I'm feeling okay today, not particularly good or bad. Just going through the day as usual.",
  ),
  _ChipData(
    label: 'Happy',
    emoji: '😄',
    color: kYellow,
    phrase:
        "I'm feeling happy and positive today! Things have been going well and I'm in a really good mood.",
  ),
];

const _kLanguages = [
  ('Malayalam', 'മലയാളം'),
  ('Hindi', 'हिन्दी'),
  ('English', 'English'),
  ('Tamil', 'தமிழ்'),
];

// ─── Screen ───────────────────────────────────────────────────────────────────
class MoodInputScreen extends StatefulWidget {
  const MoodInputScreen({super.key});
  @override
  State<MoodInputScreen> createState() => _MoodInputScreenState();
}

class _MoodInputScreenState extends State<MoodInputScreen>
    with TickerProviderStateMixin {
  // controllers
  late final List<AnimationController> _chipFloatCtrl;
  late final AnimationController _micPulseCtrl;
  late final List<AnimationController> _vbarCtrl;
  late final AnimationController _ctaFloatCtrl;
  late final AnimationController _ctaRingCtrl;
  late final AnimationController _spinCtrl;
  // entrance
  late final AnimationController _topBarCtrl;
  late final AnimationController _greetCtrl;
  late final AnimationController _chipsLabelCtrl;
  late final AnimationController _chipsCtrl;
  late final AnimationController _inputCtrl;
  late final AnimationController _langCtrl;
  late final AnimationController _ctaCtrl;
  late final AnimationController _tipCtrl;
  // mini player
  late final AnimationController _playerProgressCtrl;
  late final AnimationController _playerAlbumCtrl;

  // state
  int? _selectedChip;
  final Set<int> _selectedLangs = {2}; // Default to English (index 2)
  bool _analyzing = false;
  int _bottomNavIdx = 0; // 0=home,1=mood,2=history,3=settings
  final _textCtrl = TextEditingController();
  final _textFocus = FocusNode();

  // PERF: use ValueNotifiers instead of full-screen setState
  final ValueNotifier<bool> _recordingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _inputFocusedNotifier = ValueNotifier(false);

  // PERF: throttle speech recognition
  int _lastSpeechUpdateTime = 0;

  // ── Speech to text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;

  void _after(int ms, VoidCallback fn) =>
      Future.delayed(Duration(milliseconds: ms), () {
        if (mounted) fn();
      });

  @override
  void initState() {
    super.initState();

    const chipDur = [4000, 4600, 3800, 4300];
    _chipFloatCtrl = List.generate(4, (i) {
      final c = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: chipDur[i]),
      );
      _after(i * 200, () => c.repeat(reverse: true));
      return c;
    });

    _micPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    const vbarDur = [600, 540, 570, 510, 580, 550, 620];
    _vbarCtrl = List.generate(7, (i) {
      final c = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: vbarDur[i]),
      );
      _after(i * 50, () => c.repeat(reverse: true));
      return c;
    });

    _ctaFloatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
    _ctaRingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat();

    // entrance stagger
    _topBarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _greetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _chipsLabelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _chipsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _inputCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _langCtrl = AnimationController(
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

    _after(100, _greetCtrl.forward);
    _after(180, _chipsLabelCtrl.forward);
    _after(230, _chipsCtrl.forward);
    _after(300, _inputCtrl.forward);
    _after(360, _langCtrl.forward);
    _after(380, _ctaCtrl.forward);
    _after(440, _tipCtrl.forward);

    // mini player
    _playerProgressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 228),
    )..forward();
    _playerAlbumCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _textFocus.addListener(
      () => _inputFocusedNotifier.value = _textFocus.hasFocus,
    );

    // Init speech-to-text
    _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          _recordingNotifier.value = false;
        }
      },
      onError: (e) {
        if (mounted) _recordingNotifier.value = false;
      },
    ).then((available) {
      if (mounted) setState(() => _speechAvailable = available);
    });
  }

  void _toggleMic() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Microphone not available on this device.')),
      );
      return;
    }
    if (_recordingNotifier.value) {
      // Stop listening and keep what was transcribed
      await _speech.stop();
      _recordingNotifier.value = false;
    } else {
      _recordingNotifier.value = true;
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          // PERF: throttle updates to ~150ms to prevent text field repainting lag
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - _lastSpeechUpdateTime < 150 && !result.finalResult) return;
          _lastSpeechUpdateTime = now;

          _textCtrl.value = TextEditingValue(
            text: result.recognizedWords,
            selection:
                TextSelection.collapsed(offset: result.recognizedWords.length),
          );
        },
        localeId: 'en_US',
        listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.dictation,
            partialResults: true,
            cancelOnError: true),
      );
    }
  }

  void _analyze() {
    if (_analyzing) return;
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe how you feel first.')),
      );
      return;
    }
    final langNames =
        _selectedLangs.map((i) => _kLanguages[i].$1.toLowerCase()).toList();
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setInputText(text);
    appState.setLanguages(langNames.isEmpty ? ['english'] : langNames);
    setState(() => _analyzing = true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ProcessingScreen()),
    );
  }

  @override
  void dispose() {
    for (final c in _chipFloatCtrl) {
      c.dispose();
    }
    _micPulseCtrl.dispose();
    for (final c in _vbarCtrl) {
      c.dispose();
    }
    _ctaFloatCtrl.dispose();
    _ctaRingCtrl.dispose();
    _spinCtrl.dispose();
    _topBarCtrl.dispose();
    _greetCtrl.dispose();
    _chipsLabelCtrl.dispose();
    _chipsCtrl.dispose();
    _inputCtrl.dispose();
    _langCtrl.dispose();
    _ctaCtrl.dispose();
    _tipCtrl.dispose();
    _playerProgressCtrl.dispose();
    _playerAlbumCtrl.dispose();
    _textCtrl.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, cs) {
          final W = cs.maxWidth;
          final H = cs.maxHeight;
          return Stack(
            children: [
              _background(W, H),
              _scrollContent(W),
              // bottom chrome: mini player + nav bar (no background — waves show through)
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
    return Positioned.fill(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(W * 0.067, 0, W * 0.067, 260),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _fadeUp(_topBarCtrl, _topBar()),
              const SizedBox(height: 24),
              _fadeUp(_greetCtrl, _greeting()),
              const SizedBox(height: 20),
              _fadeUp(_chipsLabelCtrl, _sectionLabel('Quick select your mood')),
              const SizedBox(height: 8),
              _fadeUp(_chipsCtrl, _chipsRow()),
              const SizedBox(height: 18),
              _fadeUp(_inputCtrl, _inputCard()),
              const SizedBox(height: 14),
              // Language selection — only shown if multilingual feature is enabled
              Consumer<AppState>(
                builder: (_, appState, __) => appState.featureMultilingual
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fadeUp(_langCtrl, _sectionLabel('Music language')),
                          const SizedBox(height: 8),
                          _fadeUp(_langCtrl, _langRow()),
                          const SizedBox(height: 16),
                        ],
                      )
                    : const SizedBox(height: 16),
              ),
              _fadeUp(_ctaCtrl, _analyzeBtn()),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Top bar ─────────────────────────────────────────────────────────────────
  Widget _topBar() {
    return Center(
      child: Text(
        'HOW ARE YOU FEELING?',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.45),
          letterSpacing: 0.14 * 13,
        ),
      ),
    );
  }

  // ─── Greeting ─────────────────────────────────────────────────────────────────
  Widget _greeting() {
    final appState = Provider.of<AppState>(context, listen: false);
    final name = appState.userName;
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'serif',
          fontSize: 28,
          fontWeight: FontWeight.w300,
          fontStyle: FontStyle.italic,
          color: Color(0xFFF0F0FF),
          height: 1.30,
        ),
        children: [
          TextSpan(text: name.isNotEmpty ? 'Hey, ' : 'Share your '),
          WidgetSpan(
            child: ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [kOrange, kPink],
              ).createShader(b),
              child: Text(
                name.isNotEmpty ? name : 'emotions',
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
          TextSpan(
              text: name.isNotEmpty
                  ? '\nHow are you feeling today?'
                  : '\nwith us today'),
        ],
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

  // ─── Chips row ────────────────────────────────────────────────────────────────
  Widget _chipsRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_kChips.length, (i) {
        final chip = _kChips[i];
        final sel = _selectedChip == i;
        return AnimatedBuilder(
          animation: _chipFloatCtrl[i],
          builder: (_, __) {
            const floatY = 0.0;
            return Transform.translate(
              offset: const Offset(0, floatY),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedChip = i);
                  _textCtrl.text = chip.phrase;
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: sel
                            ? chip.color.withValues(alpha: 0.22)
                            : chip.color.withValues(alpha: 0.12),
                        border: Border.all(
                          color: sel
                              ? chip.color.withValues(alpha: 0.55)
                              : chip.color.withValues(alpha: 0.28),
                        ),
                        // ── glass shadow system ──
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  offset: const Offset(0, 1),
                                  blurRadius: 0,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF000000)
                                      .withValues(alpha: 0.15),
                                  offset: const Offset(0, -1),
                                  blurRadius: 0,
                                ),
                                BoxShadow(
                                  color: chip.color.withValues(alpha: 0.20),
                                  blurRadius: 18,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF000000)
                                      .withValues(alpha: 0.22),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.10),
                                  offset: const Offset(0, 1),
                                  blurRadius: 0,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF000000)
                                      .withValues(alpha: 0.15),
                                  offset: const Offset(0, -1),
                                  blurRadius: 0,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF000000)
                                      .withValues(alpha: 0.18),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                gradient: const LinearGradient(
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                chip.emoji,
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                chip.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: chip.color.withValues(
                                    alpha: sel ? 0.98 : 0.90,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // ─── Input card ───────────────────────────────────────────────────────────────
  Widget _inputCard() {
    return ValueListenableBuilder<bool>(
      valueListenable: _inputFocusedNotifier,
      builder: (context, inputFocused, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: inputFocused
                      ? kOrange.withValues(alpha: 0.30)
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
                    color: const Color(0xFF000000).withValues(alpha: 0.25),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                  if (inputFocused)
                    BoxShadow(
                      color: kOrange.withValues(alpha: 0.07),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                ],
              ),
              child: Stack(
                children: [
                  // top shine
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // textarea
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textCtrl,
                              focusNode: _textFocus,
                              maxLines: 5,
                              maxLength: 300,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.88),
                                height: 1.65,
                              ),
                              cursorColor: kOrange.withValues(alpha: 0.90),
                              decoration: InputDecoration(
                                hintText: 'Tell us how you feel today…',
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                counterText: '',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // footer row
                      Container(
                        padding: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                                color: Colors.white.withValues(alpha: 0.07)),
                          ),
                        ),
                        child: Row(
                          children: [
                            // voice bars
                            AnimatedOpacity(
                              opacity: _recordingNotifier.value ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: Row(
                                children: List.generate(7, (i) {
                                  const heights = [
                                    8.0,
                                    14.0,
                                    10.0,
                                    18.0,
                                    11.0,
                                    16.0,
                                    8.0,
                                  ];
                                  return AnimatedBuilder(
                                    animation: _vbarCtrl[i],
                                    builder: (_, __) => Container(
                                      width: 3,
                                      height: _lerp(
                                        3,
                                        heights[i],
                                        _vbarCtrl[i].value,
                                      ),
                                      margin: const EdgeInsets.only(right: 3),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(2),
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            kOrange.withValues(alpha: 0.80),
                                            const Color(0xFFFCB464),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // char count
                            AnimatedBuilder(
                              animation: _textCtrl,
                              builder: (_, __) => Text(
                                '${_textCtrl.text.length} / 300',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.25),
                                  letterSpacing: 0.04 * 11,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // mic button — only shown if voice input feature is enabled
                            if (context.read<AppState>().featureVoiceInput)
                            GestureDetector(
                              onTap: _toggleMic,
                              child: ValueListenableBuilder<bool>(
                                valueListenable: _recordingNotifier,
                                builder: (context, recording, _) {
                                  return AnimatedBuilder(
                                    animation: _micPulseCtrl,
                                    builder: (_, __) {
                                      final v = _micPulseCtrl.value;
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: BackdropFilter(
                                          filter: ui.ImageFilter.blur(
                                            sigmaX: 20,
                                            sigmaY: 20,
                                          ),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 250),
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              color: recording
                                                  ? kOrange.withValues(
                                                      alpha: 0.20)
                                                  : Colors.white
                                                      .withValues(alpha: 0.08),
                                              border: Border.all(
                                                color: recording
                                                    ? kOrange.withValues(
                                                        alpha: 0.48)
                                                    : Colors.white.withValues(
                                                        alpha: 0.16),
                                              ),
                                              boxShadow: recording
                                                  ? [
                                                      BoxShadow(
                                                        color: Colors.white
                                                            .withValues(
                                                          alpha: 0.38,
                                                        ),
                                                        offset:
                                                            const Offset(0, 1),
                                                        blurRadius: 0,
                                                      ),
                                                      BoxShadow(
                                                        color: const Color(
                                                                0xFF000000)
                                                            .withValues(
                                                          alpha: 0.18,
                                                        ),
                                                        offset:
                                                            const Offset(0, -1),
                                                        blurRadius: 0,
                                                      ),
                                                      BoxShadow(
                                                        color:
                                                            kOrange.withValues(
                                                          alpha: _lerp(
                                                              0.12, 0.06, v),
                                                        ),
                                                        blurRadius: 0,
                                                        spreadRadius:
                                                            _lerp(4, 8, v),
                                                      ),
                                                      BoxShadow(
                                                        color:
                                                            kOrange.withValues(
                                                          alpha: _lerp(
                                                              0.25, 0.35, v),
                                                        ),
                                                        blurRadius: 24,
                                                      ),
                                                    ]
                                                  : [
                                                      BoxShadow(
                                                        color: Colors.white
                                                            .withValues(
                                                          alpha: 0.18,
                                                        ),
                                                        offset:
                                                            const Offset(0, 1),
                                                        blurRadius: 0,
                                                      ),
                                                      BoxShadow(
                                                        color: const Color(
                                                                0xFF000000)
                                                            .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                        offset:
                                                            const Offset(0, -1),
                                                        blurRadius: 0,
                                                      ),
                                                      BoxShadow(
                                                        color: const Color(
                                                                0xFF000000)
                                                            .withValues(
                                                          alpha: 0.20,
                                                        ),
                                                        blurRadius: 12,
                                                        offset:
                                                            const Offset(0, 4),
                                                      ),
                                                    ],
                                            ),
                                            child: Stack(
                                              children: [
                                                Positioned(
                                                  top: 0,
                                                  left: 0,
                                                  right: 0,
                                                  height: 20,
                                                  child: Container(
                                                    decoration:
                                                        const BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.vertical(
                                                        top:
                                                            Radius.circular(14),
                                                      ),
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                        colors: [
                                                          Color(0x28FFFFFF),
                                                          Colors.transparent,
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Center(
                                                  child: Text(
                                                    recording ? '⏹️' : '🎙️',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Language row ─────────────────────────────────────────────────────────────
  Widget _langRow() {
    return Row(
      children: List.generate(_kLanguages.length, (i) {
        final lang = _kLanguages[i];
        final sel = _selectedLangs.contains(i);
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              if (sel) {
                // keep at least one selected
                if (_selectedLangs.length > 1) _selectedLangs.remove(i);
              } else {
                _selectedLangs.add(i);
              }
            }),
            child: Container(
              margin: EdgeInsets.only(
                right: i < _kLanguages.length - 1 ? 8 : 0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 44, sigmaY: 44),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: sel
                          ? LinearGradient(
                              colors: [
                                kOrange.withValues(alpha: 0.22),
                                kPink.withValues(alpha: 0.16),
                              ],
                            )
                          : null,
                      color: sel ? null : Colors.white.withValues(alpha: 0.06),
                      border: Border.all(
                        color: sel
                            ? kOrange.withValues(alpha: 0.45)
                            : Colors.white.withValues(alpha: 0.11),
                      ),
                      // ── glass shadow system ──
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.32),
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
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: const Color(0xFF000000)
                                    .withValues(alpha: 0.22),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.14),
                                offset: const Offset(0, 1),
                                blurRadius: 0,
                              ),
                              BoxShadow(
                                color: const Color(0xFF000000)
                                    .withValues(alpha: 0.15),
                                offset: const Offset(0, -1),
                                blurRadius: 0,
                              ),
                              BoxShadow(
                                color: const Color(0xFF000000)
                                    .withValues(alpha: 0.18),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Stack(
                      children: [
                        // top shine
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 22,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(14),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white
                                      .withValues(alpha: sel ? 0.20 : 0.12),
                                  Colors.white
                                      .withValues(alpha: sel ? 0.05 : 0.0),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              lang.$1,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: sel
                                    ? const Color(0xFFFFDCB4)
                                        .withValues(alpha: 0.98)
                                    : Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              lang.$2,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? kOrange.withValues(alpha: 0.65)
                                    : Colors.white.withValues(alpha: 0.28),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ─── Analyse button ───────────────────────────────────────────────────────────
  Widget _analyzeBtn() {
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
              GestureDetector(
                onTap: _analyze,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            kOrange.withValues(alpha: 0.28),
                            kPink.withValues(alpha: 0.22),
                          ],
                        ),
                        border:
                            Border.all(color: kOrange.withValues(alpha: 0.42)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.40),
                            offset: const Offset(0, 1),
                            blurRadius: 0,
                          ),
                          BoxShadow(
                            color:
                                const Color(0xFF000000).withValues(alpha: 0.24),
                            offset: const Offset(0, -1),
                            blurRadius: 0,
                          ),
                          BoxShadow(
                            color: kOrange.withValues(alpha: 0.18),
                            blurRadius: 32,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // top shine
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: 27,
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
                                  colors: [
                                    Color(0x28000000),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: _analyzing
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _spinner(),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Analysing…',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: 0.03 * 14,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '✦',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Analyse My Mood',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
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
            ],
          ),
        );
      },
    );
  }

  Widget _spinner() {
    return AnimatedBuilder(
      animation: _spinCtrl,
      builder: (_, __) => Transform.rotate(
        angle: _spinCtrl.value * 2 * pi,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.20), width: 2),
          ),
          child: CustomPaint(painter: _SpinnerArcPainter()),
        ),
      ),
    );
  }

  // ─── Tip content (Positioned wrapper lives in build(), not here) ──────────────

  // ─── Bottom chrome: mini player + nav bar ────────────────────────────────────
  // Waves are rendered in the main Stack BELOW this — they show through the
  // transparent gaps between and above the glass pills.
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
    // PERF: Exchanging Consumer<AppState> for exact Selectors to avoid full mini-player redraws on every progress tick
    return Builder(builder: (context) {
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
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
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
                          selector: (_, state) =>
                              state.playbackProgress.clamp(0.0, 1.0),
                          builder: (context, progress, _) {
                            return LinearProgressIndicator(
                              value: progress,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.08),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF9A6B),
                              ),
                              minHeight: 2,
                            );
                          }),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 14, 2),
                    child: Row(
                      children: [
                        Selector<AppState, bool>(
                          selector: (_, state) => state.isPlaying,
                          builder: (context, isPlaying, _) {
                            return AnimatedBuilder(
                              animation: _playerAlbumCtrl,
                              builder: (_, __) => Transform.rotate(
                                angle: isPlaying
                                    ? _playerAlbumCtrl.value * 2 * 3.1415926535
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
                                      color:
                                          Colors.white.withValues(alpha: 0.20),
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
                              final (title, artist, emoji) = songData;
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShaderMask(
                                    shaderCallback: (b) => const LinearGradient(
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
                                      color:
                                          Colors.white.withValues(alpha: 0.50),
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
                            final appState =
                                Provider.of<AppState>(context, listen: false);
                            appState.setPlaying(!appState.isPlaying);
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
                                    selector: (_, state) => state.isPlaying,
                                    builder: (context, isPlaying, _) {
                                      return Center(
                                        child: Icon(
                                          isPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      );
                                    }),
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
    });
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
                // top shine
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
                // items
                Row(
                  children: List.generate(items.length, (i) {
                    final item = items[i];
                    final sel = _bottomNavIdx == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (i == _bottomNavIdx) return;
                          setState(() => _bottomNavIdx = i);
                          if (i == 1) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NextTargetScreen(),
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
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    AnimatedScale(
                                      scale: sel ? 1.10 : 1.0,
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
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
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
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

// ─── Spinner arc ──────────────────────────────────────────────────────────────
class _SpinnerArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.90)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      -pi / 2,
      pi * 0.75,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
