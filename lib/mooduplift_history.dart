import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'mood_input.dart';
import 'next_target.dart';
import 'settings.dart';
import 'ai_insights_card.dart';

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
  runApp(const MoodHistoryApp());
}

const Color kOrange = Color(0xFFFB923C);
const Color kPink = Color(0xFFF472B6);
const Color kViolet = Color(0xFFC4B5FD);
const Color kBlue = Color(0xFF93C5FD);
const Color kGreen = Color(0xFFA7F3D0);

double _lerp(double a, double b, double t) => a + (b - a) * t;

class MoodHistoryApp extends StatelessWidget {
  const MoodHistoryApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood History',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: const Color(0xFF000000)),
      home: const HistoryScreen(),
    );
  }
}

enum MoodType { sad, calm, neutral, hopeful, happy }

class TimelineStep {
  final MoodType mood;
  final String emoji, name, time, note, phase, duration;
  final bool achieved;
  final int? intensity;

  const TimelineStep({
    required this.mood,
    required this.emoji,
    required this.name,
    required this.time,
    required this.note,
    required this.phase,
    required this.duration,
    required this.achieved,
    this.intensity,
  });
}

class SongEntry {
  final int num;
  final String emoji, title, artist, duration;
  final MoodType mood;
  final String? moodLabel;

  const SongEntry({
    required this.num,
    required this.emoji,
    required this.title,
    required this.artist,
    required this.duration,
    required this.mood,
    this.moodLabel,
  });
}

class TransitionChip {
  final String from, fromEmoji, to, toEmoji, label;
  const TransitionChip({
    required this.from,
    required this.fromEmoji,
    required this.to,
    required this.toEmoji,
    required this.label,
  });
}

const _kTimeline = [
  TimelineStep(
    mood: MoodType.sad,
    emoji: '😢',
    name: 'Sad',
    time: '7:10 PM · Session start',
    note: 'Starting mood detected',
    phase: 'Phase 1',
    duration: '—',
    achieved: false,
  ),
  TimelineStep(
    mood: MoodType.calm,
    emoji: '😌',
    name: 'Calm',
    time: '7:28 PM · After 3 songs',
    note: 'Sad → Calm achieved',
    phase: 'Phase 1',
    duration: '18 min',
    achieved: true,
  ),
  TimelineStep(
    mood: MoodType.neutral,
    emoji: '😐',
    name: 'Neutral',
    time: '7:52 PM · After 6 songs',
    note: 'Calm → Neutral achieved',
    phase: 'Phase 2',
    duration: '24 min',
    achieved: true,
  ),
  TimelineStep(
    mood: MoodType.hopeful,
    emoji: '🙂',
    name: 'Hopeful',
    time: '8:14 PM · After 9 songs',
    note: 'Neutral → Hopeful achieved',
    phase: 'Phase 2',
    duration: '22 min',
    achieved: true,
  ),
  TimelineStep(
    mood: MoodType.happy,
    emoji: '😄',
    name: 'Happy',
    time: '8:38 PM · Session end',
    note: 'Goal reached ✦',
    phase: 'Phase 3',
    duration: '24 min',
    achieved: true,
  ),
];

// removed _kTransitions

Color _moodNodeColor(MoodType m) {
  switch (m) {
    case MoodType.sad:
      return kBlue;
    case MoodType.calm:
      return kViolet;
    case MoodType.neutral:
      return kOrange;
    case MoodType.hopeful:
      return kPink;
    case MoodType.happy:
      return kGreen;
  }
}

String _moodLabel(MoodType m) {
  switch (m) {
    case MoodType.sad:
      return 'Sad';
    case MoodType.calm:
      return 'Calm';
    case MoodType.neutral:
      return 'Neutral';
    case MoodType.hopeful:
      return 'Hopeful';
    case MoodType.happy:
      return 'Happy';
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  late final AnimationController _dotCtrl;
  late final AnimationController _statCtrl;
  late final AnimationController _ctaCtrl;

  late final AnimationController _topBarCtrl;
  late final AnimationController _headCtrl;
  late final AnimationController _summaryCtrl;
  late final AnimationController _timelineCtrl;
  late final AnimationController _songsCtrl;
  late final AnimationController _transCtrl;
  late final AnimationController _ctaEntranceCtrl;
  late final AnimationController _tipCtrl;
  late final AnimationController _tapCtrl;

  // mini player
  late final AnimationController _playerProgressCtrl;
  late final AnimationController _playerAlbumCtrl;
  int _bottomNavIdx = 2; // 0=home,1=mood,2=history,3=settings

  void _after(int ms, VoidCallback fn) =>
      Future.delayed(Duration(milliseconds: ms), () {
        if (mounted) fn();
      });

  @override
  void initState() {
    super.initState();

    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _statCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _ctaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);

    _topBarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _headCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _summaryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _timelineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _songsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _transCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _ctaEntranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _tipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _after(100, _headCtrl.forward);
    _after(180, _summaryCtrl.forward);
    _after(260, () {
      _timelineCtrl.forward();
      _statCtrl.forward();
    });
    _after(320, _songsCtrl.forward);
    _after(380, _transCtrl.forward);
    _after(440, _ctaEntranceCtrl.forward);
    _after(500, _tipCtrl.forward);

    // ✅ Load AI insights when the history screen opens (only if feature enabled)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        if (appState.featureAiInsights) appState.loadAiInsights();
      }
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
    _dotCtrl.dispose();
    _statCtrl.dispose();
    _ctaCtrl.dispose();
    _topBarCtrl.dispose();
    _headCtrl.dispose();
    _summaryCtrl.dispose();
    _timelineCtrl.dispose();
    _songsCtrl.dispose();
    _transCtrl.dispose();
    _ctaEntranceCtrl.dispose();
    _tipCtrl.dispose();
    _tapCtrl.dispose();
    _playerProgressCtrl.dispose();
    _playerAlbumCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          final W = MediaQuery.of(context).size.width;
          final H = MediaQuery.of(context).size.height;

          final records = appState.history;

          return Stack(
            children: [
              _background(W, H),
              _scrollContent(W, H, records),
              Positioned(bottom: 0, left: 0, right: 0, child: _bottomChrome(W)),
            ],
          );
        },
      ),
    );
  }

  Widget _background(double W, double H) {
    return const Positioned.fill(
      child: ColoredBox(color: Color(0xFF000000)),
    );
  }

  Widget _scrollContent(double W, double H, List<SessionRecord> records) {
    return Positioned.fill(
      child: SafeArea(
        child: records.isEmpty
            ? _emptyState(W)
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(W * 0.067, 0, W * 0.067, 260),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _fadeUp(_topBarCtrl, _topBar()),
                    const SizedBox(height: 20),
                    _fadeUp(_headCtrl, _pageHeading()),
                    const SizedBox(height: 16),
                    // ✅ AI Insights section — only shown if enabled by admin
                    Consumer<AppState>(
                      builder: (_, appState, __) => appState.featureAiInsights
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fadeUp(_summaryCtrl, _sectionLabel('AI Insights')),
                                _fadeUp(_summaryCtrl, const AiInsightsCard()),
                                const SizedBox(height: 20),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                    ...records.map(_buildSessionBlock),
                    _fadeUp(_ctaEntranceCtrl, _ctaButton()),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _emptyState(double W) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04),
            ),
            child: Icon(
              Icons.history_rounded,
              size: 48,
              color: kOrange.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your story begins here',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 20,
              fontStyle: FontStyle.italic,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a session to see your mood journey.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _ctaButton(),
        ],
      ),
    );
  }

  Widget _buildSessionBlock(SessionRecord record) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fadeUp(_summaryCtrl, RepaintBoundary(child: _summaryCard(record))),
        if (record.isLive)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: kOrange.withValues(alpha: 0.15),
                border: Border.all(color: kOrange.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'LIVE NOW',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: kOrange,
                ),
              ),
            ),
          ),
        const SizedBox(height: 14),
        _sectionLabel('Mood Timeline'),
        RepaintBoundary(child: _timelineCard(record)),
        const SizedBox(height: 14),
        _sectionLabel('Songs Played'),
        RepaintBoundary(child: _songsCard(record)),
        const SizedBox(height: 14),
        _sectionLabel('Transitions Achieved'),
        RepaintBoundary(child: _transitionsWrap(record)),
        const SizedBox(height: 32),
        Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        const SizedBox(width: 36), // Placeholder for removed back button
        const Spacer(),
        Text(
          'MOOD HISTORY',
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

  Widget _pageHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
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
                            color: kOrange.withValues(alpha: 0.70),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
            Text(
              "TODAY'S SESSION",
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
        RichText(
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
              const TextSpan(text: 'Your emotional '),
              WidgetSpan(
                child: ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [kOrange, kPink],
                  ).createShader(b),
                  child: const Text(
                    'journey',
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
              const TextSpan(text: '\nthis session'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(SessionRecord? record) {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record != null
                                  ? record.date.toUpperCase()
                                  : 'MON, 23 FEB 2026',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.08 * 12,
                                color: Colors.white.withValues(alpha: 0.40),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              record != null
                                  ? '${record.startMood} → ${record.endMood}'
                                  : 'Evening Session',
                              style: const TextStyle(
                                fontFamily: 'serif',
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFFF0F0FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          gradient: LinearGradient(
                            colors: [
                              kOrange.withValues(alpha: 0.18),
                              kPink.withValues(alpha: 0.14),
                            ],
                          ),
                          border: Border.all(
                              color: kOrange.withValues(alpha: 0.34)),
                        ),
                        child: Text(
                          'COMPLETED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.08 * 10,
                            color: kOrange.withValues(alpha: 0.92),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _summaryStats(record),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryStats(SessionRecord? record) {
    final labels = ['Songs', 'Duration', 'Avg. Intensity'];
    final targets = [
      record?.songsPlayed.length ?? 0,
      record?.moodIntensity ?? 0,
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            _buildStatItem(labels[0], targets[0].toString(), 0),
            _buildStatItem(labels[1], record?.durationMinutes ?? '0m 0s', 1),
            _buildStatItem(labels[2], targets[1].toString(), 2, isLast: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, int index,
      {bool isLast = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          border: isLast
              ? null
              : Border(
                  right: BorderSide(
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
        ),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [kOrange, kPink],
              ).createShader(b),
              child: Text(
                value,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.05 * 9,
                color: Colors.white.withValues(alpha: 0.30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
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
      ),
    );
  }

  Widget _timelineCard(SessionRecord? record) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
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
                height: 70,
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
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 2,
                      margin: const EdgeInsets.fromLTRB(20, 4, 16, 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x8093C5FD),
                            Color(0x73C4B5FD),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Builder(builder: (ctx) {
                        const ladderNames = [
                          'Sad',
                          'Calm',
                          'Neutral',
                          'Happy',
                          'Energised'
                        ];
                        const ladderEmojis = ['😢', '😌', '😐', '😄', '🔥'];

                        final steps = <TimelineStep>[];
                        final sMood = record?.startMood ?? 'Sad';
                        final itemDate = record?.date ?? '—';

                        // 1. Initial Step
                        final dateParts =
                            record?.date.split(' • ') ?? ['—', '—'];
                        final startTime =
                            dateParts.length > 1 ? dateParts.last : '—';

                        final startStep = TimelineStep(
                          mood: _moodType(sMood),
                          emoji: AppState.moodEmoji(sMood),
                          name: sMood,
                          time: '$startTime · Session start',
                          note: 'Starting mood detected',
                          phase: 'Start',
                          duration: '',
                          achieved: false,
                          intensity: record?.intensities.isNotEmpty == true
                              ? record!.intensities.first
                              : null,
                        );
                        steps.add(startStep);

                        // 2. Journey transitions
                        if (record != null) {
                          for (int i = 0; i < record.transitions.length; i++) {
                            final t = record.transitions[i];
                            steps.add(TimelineStep(
                              mood: _moodType(t.to),
                              emoji: t.toEmoji,
                              name: t.to,
                              time: '${t.time} · Phase achieved',
                              note: '${t.from} → ${t.to} achieved',
                              phase: 'Phase ${i + 2}',
                              duration: '',
                              achieved: true,
                              intensity: t.intensity,
                            ));
                          }
                        }

                        // 3. Next Target (Live only)
                        if (record?.isLive ?? false) {
                          final currentMood = record!.transitions.isNotEmpty
                              ? record.transitions.last.to
                              : sMood;

                          int curIdx = ladderNames.indexWhere((n) =>
                              n.toLowerCase() == currentMood.toLowerCase());
                          if (curIdx < 0) curIdx = 0;

                          if (curIdx + 1 < ladderNames.length) {
                            final nMood = ladderNames[curIdx + 1];
                            final nEmoji = ladderEmojis[curIdx + 1];
                            steps.add(TimelineStep(
                              mood: _moodType(nMood),
                              emoji: nEmoji,
                              name: nMood,
                              time: itemDate.contains('•')
                                  ? itemDate.split('•').last.trim()
                                  : 'Upcoming',
                              note: 'NEXT TARGET',
                              phase: 'Phase ${steps.length + 1}',
                              duration: '',
                              achieved: false,
                            ));
                          }
                        }

                        return Column(
                          children:
                              steps.map((s) => _buildTimelineStep(s)).toList(),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep(TimelineStep step) {
    final nodeColor = _moodNodeColor(step.mood);
    final isLast = step == _kTimeline.last;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom:
                    BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: const Offset(-26, 2),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: nodeColor.withValues(alpha: 0.12),
                border: Border.all(
                  color: nodeColor.withValues(alpha: 0.70),
                  width: 2,
                ),
                boxShadow: step.mood == MoodType.happy
                    ? [
                        BoxShadow(
                          color: nodeColor.withValues(alpha: 0.35),
                          blurRadius: 8,
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
                    color: nodeColor.withValues(alpha: 0.90),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 26,
            child: Text(
              step.emoji,
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
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
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.time,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.30),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: step.achieved
                        ? kGreen.withValues(alpha: 0.10)
                        : Colors.white.withValues(alpha: 0.06),
                    border: Border.all(
                      color: step.achieved
                          ? kGreen.withValues(alpha: 0.22)
                          : Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: step.achieved
                              ? kGreen.withValues(alpha: 0.80)
                              : Colors.white.withValues(alpha: 0.42),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        step.note.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.06 * 9,
                          color: step.achieved
                              ? kGreen.withValues(alpha: 0.80)
                              : Colors.white.withValues(alpha: 0.42),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: kOrange.withValues(alpha: 0.12),
                  border: Border.all(color: kOrange.withValues(alpha: 0.22)),
                ),
                child: Text(
                  step.phase.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.08 * 9,
                    color: kOrange.withValues(alpha: 0.85),
                  ),
                ),
              ),
              if (step.intensity != null) ...[
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    '${step.intensity}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: kOrange.withValues(alpha: 0.60),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                step.duration,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.30),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _songsCard(SessionRecord? record) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
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
                color: const Color(0xFF000000).withValues(alpha: 0.25),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: (record != null && record.songsPlayed.isNotEmpty)
                ? record.songsPlayed
                    .asMap()
                    .entries
                    .map((e) => SongEntry(
                          num: e.key + 1,
                          emoji: e.value.emoji,
                          title: e.value.title,
                          artist: e.value.artist,
                          duration: '',
                          mood: _moodType(e.value.playedInMood ?? 'neutral'),
                          moodLabel: e.value.playedInMood,
                        ))
                    .toList()
                    .asMap()
                    .entries
                    .map((e) {
                    final i = e.key;
                    final song = e.value;
                    final itemsCount = record.songsPlayed.length;
                    final isLast = i == itemsCount - 1;
                    return _buildSongRow(song, isLast);
                  }).toList()
                : [
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No songs played yet in this session',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.25),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildSongRow(SongEntry song, bool isLast) {
    final moodColor = _moodNodeColor(song.mood);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 13, 18, 13),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom:
                    BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text(
              '${song.num}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.22),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.3),
                colors: [moodColor.withValues(alpha: 0.55), Colors.transparent],
                radius: 0.9,
              ),
              color: const Color(0xFF1A1830),
            ),
            child: Center(
              child: Text(song.emoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  song.artist,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.38),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                song.duration,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.30),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: moodColor.withValues(alpha: 0.12),
                  border: Border.all(color: moodColor.withValues(alpha: 0.22)),
                ),
                child: Text(
                  (song.moodLabel ?? _moodLabel(song.mood)).toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.06 * 8,
                    color: moodColor.withValues(alpha: 0.80),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _transitionsWrap(SessionRecord record) {
    if (record.transitions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'Journeying towards your goal...',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: record.transitions.map(_buildTransChip).toList(),
    );
  }

  Widget _buildTransChip(MoodTransition trans) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            gradient: LinearGradient(
              colors: [
                kOrange.withValues(alpha: 0.12),
                kPink.withValues(alpha: 0.10)
              ],
            ),
            border: Border.all(color: kOrange.withValues(alpha: 0.30)),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.10),
                offset: const Offset(0, 1),
                blurRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.18),
                offset: const Offset(0, -1),
                blurRadius: 0,
              ),
              BoxShadow(color: kOrange.withValues(alpha: 0.12), blurRadius: 14),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(trans.fromEmoji, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 7),
              Text(
                '→',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.30),
                ),
              ),
              const SizedBox(width: 7),
              Text(trans.toEmoji, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 7),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [kOrange, kPink],
                ).createShader(b),
                child: Text(
                  '${trans.from} → ${trans.to}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                '✦',
                style: TextStyle(
                  fontSize: 11,
                  color: kOrange.withValues(alpha: 0.70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ctaButton() {
    return AnimatedBuilder(
      animation: _ctaCtrl,
      builder: (_, __) {
        const float = 0.0;
        return Transform.translate(
          offset: const Offset(0, float),
          child: AnimatedBuilder(
            animation: _tapCtrl,
            builder: (_, __) {
              final tap = CurvedAnimation(
                parent: _tapCtrl,
                curve: Curves.easeOut,
              ).value;
              return Stack(
                children: [
                  // ambient floating ring
                  AnimatedBuilder(
                    animation: _ctaCtrl,
                    builder: (_, __) {
                      final s = _lerp(1.0, 1.04, _ctaCtrl.value);
                      final op = _lerp(0.5, 0, _ctaCtrl.value);
                      return Transform.scale(
                        scale: s,
                        child: Opacity(
                          opacity: op,
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(21),
                              border: Border.all(
                                color: kOrange.withValues(alpha: 0.16),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // tap burst glow ring — expands and fades on press
                  Transform.scale(
                    scale: _lerp(1.0, 1.10, tap),
                    child: Opacity(
                      opacity: _lerp(0, 0.85, tap),
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: kOrange.withValues(alpha: 0.70),
                              blurRadius: _lerp(0, 32, tap),
                              spreadRadius: _lerp(0, 4, tap),
                            ),
                            BoxShadow(
                              color: kPink.withValues(alpha: 0.50),
                              blurRadius: _lerp(0, 48, tap),
                              spreadRadius: _lerp(0, 2, tap),
                            ),
                          ],
                          border: Border.all(
                            color:
                                kOrange.withValues(alpha: _lerp(0, 0.90, tap)),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTapDown: (_) => _tapCtrl.forward(),
                    onTapUp: (_) {
                      _tapCtrl.reverse();
                      // Redirect to Home (MoodInputScreen)
                      Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const MoodInputScreen()),
                          (route) => false);
                    },
                    onTapCancel: () => _tapCtrl.reverse(),
                    child: Transform.scale(
                      scale: _lerp(1.0, 0.97, tap),
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
                                  Color.lerp(
                                    kOrange.withValues(alpha: 0.28),
                                    kOrange.withValues(alpha: 0.55),
                                    tap,
                                  )!,
                                  Color.lerp(
                                    kPink.withValues(alpha: 0.22),
                                    kPink.withValues(alpha: 0.48),
                                    tap,
                                  )!,
                                ],
                              ),
                              border: Border.all(
                                color: kOrange.withValues(
                                  alpha: _lerp(0.42, 0.90, tap),
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  offset: const Offset(0, 1),
                                  blurRadius: 0,
                                ),
                                BoxShadow(
                                  color: kOrange.withValues(
                                    alpha: _lerp(0.18, 0.60, tap),
                                  ),
                                  blurRadius: _lerp(32, 56, tap),
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
                                  height: 27,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(18),
                                      ),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          const Color(
                                            0x33FFFFFF,
                                          ).withValues(
                                              alpha: _lerp(0.20, 0.45, tap)),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '✦',
                                        style: TextStyle(
                                          fontSize: _lerp(18, 22, tap),
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Start New Session',
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
                  ),
                ],
              );
            },
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
                          const SizedBox(width: 8),
                          Selector<AppState, bool>(
                            selector: (_, state) => state.featureSkipSong,
                            builder: (context, skip, _) {
                              if (!skip) return const SizedBox();
                              return Row(
                                children: [
                                  _playerBtn(
                                    icon: Icons.skip_previous_rounded,
                                    onTap: () {
                                      Provider.of<AppState>(context, listen: false)
                                          .previousTrack();
                                    },
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                ]
                              );
                            }
                          ),
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
                          const SizedBox(width: 8),
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
                          } else if (i == 1) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NextTargetScreen(),
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

  MoodType _moodType(String m) {
    switch (m.toLowerCase()) {
      case 'sad':
        return MoodType.sad;
      case 'calm':
        return MoodType.calm;
      case 'neutral':
        return MoodType.neutral;
      case 'hopeful':
        return MoodType.hopeful;
      case 'happy':
        return MoodType.happy;
      case 'energised':
      case 'energetic':
      case 'fire':
        return MoodType.happy;
      default:
        return MoodType.neutral;
    }
  }
}
