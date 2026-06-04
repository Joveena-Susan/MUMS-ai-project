import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'api_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

const Color kViolet = Color(0xFF8B5CF6);
const Color kPink = Color(0xFFEC4899);

class GlobalFeedbackSheet extends StatefulWidget {
  final VoidCallback onClose;
  const GlobalFeedbackSheet({super.key, required this.onClose});

  @override
  State<GlobalFeedbackSheet> createState() => _GlobalFeedbackSheetState();
}

class _GlobalFeedbackSheetState extends State<GlobalFeedbackSheet>
    with TickerProviderStateMixin {
  int? _selectedMood;
  double _intensity = 0.5;
  bool _voiceActive = false;
  bool _showConfirm = false;
  final _textCtrl = TextEditingController();
  final _textFocus = FocusNode();
  bool _textFocused = false;
  bool _isSubmitting = false;
  List<String> _localLanguages = [];

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  final List<String> _allLanguages = [
    'english',
    'malayalam',
    'hindi',
    'tamil',
  ];

  late final AnimationController _eyebrowDotCtrl;
  late final AnimationController _voiceRippleCtrl;
  late final AnimationController _confirmCtrl;

  @override
  void initState() {
    super.initState();
    _eyebrowDotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _voiceRippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _confirmCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textFocus.addListener(
      () => setState(() => _textFocused = _textFocus.hasFocus),
    );
    _speech
        .initialize(
      onError: (e) => debugPrint('STT Error: $e'),
    )
        .then((available) {
      if (mounted) setState(() => _speechAvailable = available);
    });
    final appState = Provider.of<AppState>(context, listen: false);
    _localLanguages = List.from(appState.selectedLanguages);
  }

  @override
  void dispose() {
    _eyebrowDotCtrl.dispose();
    _voiceRippleCtrl.dispose();
    _confirmCtrl.dispose();
    _textCtrl.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  void _submit() async {
    if (_showConfirm || _isSubmitting) return;

    if (_isSubmitting) return;

    _textFocus.unfocus();
    setState(() => _isSubmitting = true);

    try {
      final appState = Provider.of<AppState>(context, listen: false);

      // Build text for the API. E.g "User felt Better. Here's what they said: <text>"
      final moods = ['sad', 'neutral', 'better', 'happy', 'energised'];
      String baseMood =
          _selectedMood != null ? moods[_selectedMood!] : 'neutral';

      int numIntensity = (_intensity * 10).round();
      String fullFeedback = "I feel $baseMood with intensity $numIntensity.";

      if (_textCtrl.text.trim().isNotEmpty) {
        fullFeedback += " ${_textCtrl.text.trim()}";
      }

      // Request songs directly using the generated feedback string
      // just like the home section
      final songRes = await ApiService.getSongs(
        text: fullFeedback,
        languages: _localLanguages,
        limit: 15,
        email: appState.userEmail,
        blocked: appState.blockedSongs,
        liked: appState.likedSongs,
      );

      // Also update global selected languages for future sessions
      appState.setLanguages(_localLanguages);

      appState.setApiResult(
        currentMood: songRes.currentMood,
        targetMood: songRes.targetMood,
        intensity: songRes.intensity,
        songs: songRes.songs,
        isUpdate: true,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update journey: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _showConfirm = true;
        });
        _confirmCtrl.forward();

        // Auto-close backend after 1.5s
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            widget.onClose();
            Navigator.of(context).pop();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1535).withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(
              color: Colors.white.withValues(alpha: 0.12), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.50),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
          BoxShadow(
            color: kViolet.withValues(alpha: 0.15),
            blurRadius: 50,
            offset: const Offset(0, -20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: const SizedBox(),
              ),
            ),
            // Light leak
            Positioned(
              top: -60,
              left: 40,
              right: 40,
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      kViolet.withValues(alpha: 0.20),
                      Colors.transparent
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Handle
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          _header(),
                          const SizedBox(height: 24),
                          _emojiRow(),
                          const SizedBox(height: 24),
                          _intensityBlock(),
                          const SizedBox(height: 24),
                          _textFeedback(),
                          const SizedBox(height: 16),
                          // Voice button — only if voice input feature is enabled
                          Consumer<AppState>(
                            builder: (_, appState, __) => appState.featureVoiceInput
                                ? _voiceButton()
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 24),
                          // Language select — only if multilingual feature is enabled
                          Consumer<AppState>(
                            builder: (_, appState, __) => appState.featureMultilingual
                                ? _languageSelect()
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 24),
                          _submitButton(),
                        ],
                      ),
                    ),
                  ),
                  if (_showConfirm) Positioned.fill(child: _confirmOverlay()),
                  Positioned(
                    top: -12,
                    right: -12,
                    child: IconButton(
                      icon: Icon(Icons.close,
                          color: Colors.white.withValues(alpha: 0.5)),
                      onPressed: () {
                        final appState =
                            Provider.of<AppState>(context, listen: false);
                        appState.nextTrack();
                        widget.onClose();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _eyebrowDotCtrl,
              builder: (_, __) {
                return Opacity(
                  opacity: _lerp(0.3, 1.0, _eyebrowDotCtrl.value),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kPink,
                      boxShadow: [
                        BoxShadow(
                          color: kPink.withValues(alpha: 0.6),
                          blurRadius: 8 * _eyebrowDotCtrl.value,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
            Text(
              'SESSION COMPLETE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.18 * 10,
                color: kViolet.withValues(alpha: 0.70),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 28,
              fontWeight: FontWeight.w300,
              fontStyle: FontStyle.italic,
              color: Color(0xFFF5F0FF),
              height: 1.20,
              letterSpacing: -0.28,
            ),
            children: [
              const TextSpan(text: 'How are you\n'),
              WidgetSpan(
                child: ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [kViolet, kPink],
                  ).createShader(b),
                  child: const Text(
                    'feeling now?',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.normal,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your feedback helps us tune the next journey',
          style: TextStyle(
              fontSize: 12, color: Colors.white.withValues(alpha: 0.38)),
        ),
      ],
    );
  }

  Widget _emojiRow() {
    const moods = [
      ('😢', 'Still sad'),
      ('😐', 'Neutral'),
      ('🙂', 'Better'),
      ('😄', 'Happy'),
      ('🔥', 'Energised'),
    ];
    return Row(
      children: moods.asMap().entries.map((e) {
        final i = e.key;
        final face = e.value.$1;
        final label = e.value.$2;
        final sel = _selectedMood == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedMood = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: EdgeInsets.only(right: i < 4 ? 6.0 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: sel
                    ? kViolet.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.06),
                border: Border.all(
                  color: sel
                      ? kViolet.withValues(alpha: 0.42)
                      : Colors.white.withValues(alpha: 0.10),
                ),
                boxShadow: sel
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.10),
                          offset: const Offset(0, 1),
                          blurRadius: 0,
                        ),
                        BoxShadow(
                          color: kViolet.withValues(alpha: 0.20),
                          blurRadius: 20,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  AnimatedScale(
                    scale: sel ? 1.18 : 1.0,
                    duration: const Duration(milliseconds: 220),
                    child: Text(
                      face,
                      style: const TextStyle(fontSize: 24, height: 1),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.06 * 9,
                      color: sel
                          ? kViolet.withValues(alpha: 0.85)
                          : Colors.white.withValues(alpha: 0.42),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _intensityBlock() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'INTENSITY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.10 * 11,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
            Text(
              '${(_intensity * 10).round()}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kViolet.withValues(alpha: 0.90),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (ctx, cs) => GestureDetector(
            onTapDown: (d) => setState(
              () => _intensity = (d.localPosition.dx / cs.maxWidth).clamp(
                0.0,
                1.0,
              ),
            ),
            onHorizontalDragUpdate: (d) => setState(
              () => _intensity = (d.localPosition.dx / cs.maxWidth).clamp(
                0.0,
                1.0,
              ),
            ),
            child: SizedBox(
              height: 20,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: _intensity,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kViolet, kPink],
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: kPink.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: (_intensity * cs.maxWidth) - 10,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF000000).withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                          BoxShadow(
                            color: kPink.withValues(alpha: 0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: kPink,
                          ),
                        ),
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

  Widget _textFeedback() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: _textFocused
            ? [
                BoxShadow(
                  color: kViolet.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: _textFocused
                    ? kViolet.withValues(alpha: 0.38)
                    : Colors.white.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.08),
                  offset: const Offset(0, 1),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                if (_textFocused)
                  BoxShadow(
                    color: kViolet.withValues(alpha: 0.12),
                    blurRadius: 0,
                    spreadRadius: 3,
                  ),
              ],
            ),
            child: TextField(
              controller: _textCtrl,
              focusNode: _textFocus,
              maxLines: 2,
              minLines: 2,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.80),
                height: 1.5,
              ),
              cursorColor: kViolet.withValues(alpha: 0.90),
              decoration: InputDecoration(
                hintText: 'Anything else on your mind? (optional)',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.28),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _voiceButton() {
    return GestureDetector(
      onTap: () async {
        if (!_speechAvailable) {
          bool available = await _speech.initialize();
          if (!available) return;
          setState(() => _speechAvailable = true);
        }
        if (_voiceActive) {
          await _speech.stop();
          setState(() => _voiceActive = false);
        } else {
          setState(() => _voiceActive = true);
          bool hasOldText = _textCtrl.text.isNotEmpty;
          String prefix = hasOldText ? "${_textCtrl.text} " : "";
          await _speech.listen(
            onResult: (res) {
              setState(() {
                _textCtrl.text = prefix + res.recognizedWords;
              });
            },
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: _voiceActive
              ? kPink.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.055),
          border: Border.all(
            color: _voiceActive
                ? kPink.withValues(alpha: 0.36)
                : Colors.white.withValues(alpha: 0.10),
          ),
          boxShadow: _voiceActive
              ? [
                  BoxShadow(
                      color: kPink.withValues(alpha: 0.18), blurRadius: 20)
                ]
              : null,
        ),
        child: Row(
          children: [
            const Text('🎙', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _voiceActive ? 'Recording… tap to stop' : 'Record a voice note',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _voiceActive
                      ? kPink.withValues(alpha: 0.90)
                      : Colors.white.withValues(alpha: 0.50),
                ),
              ),
            ),
            if (_voiceActive)
              AnimatedBuilder(
                animation: _voiceRippleCtrl,
                builder: (_, __) {
                  final v = _voiceRippleCtrl.value;
                  return Transform.scale(
                    scale: _lerp(1.0, 1.4, v),
                    child: Opacity(
                      opacity: _lerp(1.0, 0.7, v),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kPink.withValues(alpha: 0.70),
                          boxShadow: [
                            BoxShadow(
                              color: kPink.withValues(alpha: 0.5),
                              blurRadius: 6 * v,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _languageSelect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LANGUAGES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.10 * 11,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allLanguages.map((lang) {
            final isSel = _localLanguages.contains(lang);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSel) {
                    if (_localLanguages.length > 1) {
                      _localLanguages.remove(lang);
                    }
                  } else {
                    _localLanguages.add(lang);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: isSel
                      ? kViolet.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.045),
                  border: Border.all(
                    color: isSel
                        ? kViolet.withValues(alpha: 0.42)
                        : Colors.white.withValues(alpha: 0.10),
                  ),
                  boxShadow: isSel
                      ? [
                          BoxShadow(
                              color: kViolet.withValues(alpha: 0.15),
                              blurRadius: 10)
                        ]
                      : null,
                ),
                child: Text(
                  lang[0].toUpperCase() + lang.substring(1),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                    color: isSel
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _submitButton() {
    return GestureDetector(
      onTap: _submit,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xF2A78BFA), Color(0xE68B5CF6)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.22),
              offset: const Offset(0, 1),
              blurRadius: 0,
            ),
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.18),
              offset: const Offset(0, -2),
              blurRadius: 0,
            ),
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.40),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
            BoxShadow(color: kViolet.withValues(alpha: 0.18), blurRadius: 60),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
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
                      top: Radius.circular(20),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x38FFFFFF), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSubmitting)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  else ...[
                    const Text(
                      'Submit Feedback',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.56,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '→',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _confirmOverlay() {
    return AnimatedBuilder(
      animation: _confirmCtrl,
      builder: (_, __) {
        final v = CurvedAnimation(
          parent: _confirmCtrl,
          curve: Curves.easeOut,
        ).value;
        return Opacity(
          opacity: v,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              gradient: RadialGradient(
                center: const Alignment(0, -0.4),
                radius: 1.2,
                colors: [kViolet.withValues(alpha: 0.30), Colors.transparent],
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1E1535), Color(0xFF17112C)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Transform.scale(
                        scale: _lerp(0, 1.4, v),
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                kViolet.withValues(alpha: 0.50),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: _lerp(0.3, 1.0, v),
                      child: Opacity(
                        opacity: v,
                        child: const Text('🎉', style: TextStyle(fontSize: 60)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Opacity(
                      opacity: v,
                      child: const Text(
                        'Thank you!',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 30,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFFF5F0FF),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Opacity(
                      opacity: v,
                      child: Text(
                        'Your journey continues.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.50),
                        ),
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
}

void showGlobalFeedback() {
  final context = AppState.navigatorKey.currentContext;
  if (context == null) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xFF000000).withValues(alpha: 0.6),
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.only(top: 80),
        child: GlobalFeedbackSheet(
          onClose: () {},
        ),
      );
    },
  );
}
