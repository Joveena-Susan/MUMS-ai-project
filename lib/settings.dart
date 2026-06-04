import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'mooduplift_splash.dart';
import 'mood_input.dart';
import 'next_target.dart';
import 'mooduplift_history.dart';

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
  runApp(const SettingsApp());
}

// ─── Palette ──────────────────────────────────────────────────────────────────
const Color kOrange = Color(0xFFFB923C);
const Color kPink = Color(0xFFF472B6); // rgba(244,114,182)
const Color kViolet = Color(0xFFA78BFA); // rgba(167,139,250)
const Color kIndigo = Color(0xFF6366F1); // rgba(99,102,241)
const Color kBlue = Color(0xFF93C5FD);
const Color kGreen = Color(0xFFA7F3D0);
const Color kYellow = Color(0xFFFBBF24);
const Color kRed = Color(0xFFF87171);

double _lerp(double a, double b, double t) => a + (b - a) * t;

class SettingsApp extends StatelessWidget {
  const SettingsApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoodUplift – Settings',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: const Color(0xFF000000)),
      home: const SettingsScreen(),
    );
  }
}

// ─── Data models ─────────────────────────────────────────────────────────────
class LangOption {
  final String name, native;
  const LangOption(this.name, this.native);
}

class GenreOption {
  final String emoji, label;
  const GenreOption(this.emoji, this.label);
}

// ─── Settings Screen ──────────────────────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _dotCtrl;
  // entrance
  late final AnimationController _topBarCtrl;
  late final AnimationController _headCtrl;
  late final AnimationController _accountCtrl;
  late final AnimationController _genreCtrl;
  late final AnimationController _toggleCtrl;
  late final AnimationController _logoutCtrl;
  late final AnimationController _tipCtrl;

  // logout press
  late AnimationController _logoutPressCtrl;

  // mini player
  late final AnimationController _playerProgressCtrl;
  late final AnimationController _playerAlbumCtrl;
  int _bottomNavIdx = 3; // 0=home,1=mood,2=history,3=settings

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

    // entrance controllers
    _topBarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _headCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _accountCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _genreCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _toggleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _logoutCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _tipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _after(100, _headCtrl.forward);
    _after(180, _accountCtrl.forward);
    _after(300, _genreCtrl.forward);
    _after(360, _toggleCtrl.forward);
    _after(420, _logoutCtrl.forward);
    _after(480, _tipCtrl.forward);

    // logout press
    _logoutPressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

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
    _topBarCtrl.dispose();
    _headCtrl.dispose();
    _accountCtrl.dispose();
    _genreCtrl.dispose();
    _toggleCtrl.dispose();
    _logoutCtrl.dispose();
    _tipCtrl.dispose();
    _logoutPressCtrl.dispose();
    _playerProgressCtrl.dispose();
    _playerAlbumCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: LayoutBuilder(
        builder: (context, cs) {
          final W = cs.maxWidth;
          final H = cs.maxHeight;
          return Stack(
            children: [
              _background(W, H),
              _scrollContent(W, H),
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
  Widget _scrollContent(double W, double H) {
    return Positioned.fill(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(W * 0.067, 0, W * 0.067, 260),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _fadeUp(_topBarCtrl, _topBar()),
              const SizedBox(height: 20),
              _fadeUp(_headCtrl, _pageHeading()),
              const SizedBox(height: 18),
              // Account
              _fadeUp(_accountCtrl, _sectionLabel('Account')),
              _fadeUp(_accountCtrl, _accountCard()),
              const SizedBox(height: 14),
              // Blocked Songs
              _fadeUp(_accountCtrl, _sectionLabel('Blocked Songs')),
              _fadeUp(_accountCtrl, _blockedSongsCard()),
              const SizedBox(height: 14),
              // Clear History
              _fadeUp(_logoutCtrl, _clearHistoryButton()),
              const SizedBox(height: 14),
              // Clear Played History
              _fadeUp(_logoutCtrl, _clearPlayedHistoryButton()),
              const SizedBox(height: 14),
              // Logout
              _fadeUp(_logoutCtrl, _logoutButton()),
              const SizedBox(height: 12),
              _fadeUp(_logoutCtrl, _versionLine()),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Top bar ─────────────────────────────────────────────────────────────────
  Widget _topBar() {
    return Row(
      children: [
        const SizedBox(width: 36), // Placeholder for removed back button
        const Spacer(),
        Text(
          'SETTINGS',
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

  // ─── Page heading ─────────────────────────────────────────────────────────────
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
              'PERSONALISATION',
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
              const TextSpan(text: 'Make it truly\n'),
              WidgetSpan(
                child: ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [kOrange, kPink],
                  ).createShader(b),
                  child: const Text(
                    'yours',
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
      ],
    );
  }

  // ─── Section label ────────────────────────────────────────────────────────────
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

  // ─── Account card ─────────────────────────────────────────────────────────────
  void _showUserCredentials(BuildContext context, AppState appState) {
    bool obscurePass = true;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const Text('Account Details',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _infoRow(Icons.person_outline_rounded, 'NAME',
                  appState.userName.isNotEmpty ? appState.userName : 'Guest'),
              const SizedBox(height: 18),
              _infoRow(
                  Icons.email_outlined,
                  'EMAIL',
                  appState.userEmail.isNotEmpty
                      ? appState.userEmail
                      : 'Not signed in'),
              const SizedBox(height: 18),
              _infoRow(
                Icons.lock_outline_rounded,
                'PASSWORD',
                obscurePass
                    ? '•' * (appState.userPassword.length.clamp(6, 12))
                    : appState.userPassword,
                suffix: IconButton(
                  icon: Icon(
                    obscurePass ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white38,
                    size: 18,
                  ),
                  onPressed: () =>
                      setModalState(() => obscurePass = !obscurePass),
                ),
              ),
              if (appState.userDOB.isNotEmpty) ...[
                const SizedBox(height: 18),
                _infoRow(
                    Icons.cake_outlined, 'DATE OF BIRTH', appState.userDOB),
              ],
              if (appState.userAge.isNotEmpty) ...[
                const SizedBox(height: 18),
                _infoRow(
                    Icons.calendar_today_outlined, 'AGE', appState.userAge),
              ],
              if (appState.userGender.isNotEmpty) ...[
                const SizedBox(height: 18),
                _infoRow(
                    Icons.transgender_rounded, 'GENDER', appState.userGender),
              ],
              const SizedBox(height: 12),
            ],
          ),
        );
      }),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Widget? suffix}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: kOrange, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        if (suffix != null) suffix,
      ],
    );
  }

  Widget _accountCard() {
    final appState = Provider.of<AppState>(context, listen: false);
    return GestureDetector(
      onTap: () => _showUserCredentials(context, appState),
      child: ClipRRect(
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
                  height: 50,
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
                  children: [
                    // avatar
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: [
                            kOrange.withValues(alpha: 0.30),
                            kPink.withValues(alpha: 0.28),
                          ],
                        ),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.16),
                            offset: const Offset(0, 2),
                            blurRadius: 0,
                          ),
                          BoxShadow(
                            color: kOrange.withValues(alpha: 0.16),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('🎵', style: TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // info
                    Expanded(
                      child: Builder(builder: (ctx) {
                        final a = Provider.of<AppState>(ctx, listen: false);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.userName.isNotEmpty ? a.userName : 'Guest User',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              a.userEmail.isNotEmpty
                                  ? a.userEmail
                                  : 'Not signed in',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.38),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Blocked Songs Card ──────────────────────────────────────────────────────────
  Widget _blockedSongsCard() {
    return Consumer<AppState>(
      builder: (_, appState, __) {
        final count = appState.blockedSongs.length;
        return GestureDetector(
          onTap: () {
            if (count > 0) {
              appState.unblockAllSongs();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Unblocked $count song(s).'),
                  backgroundColor: kIndigo.withValues(alpha: 0.8),
                  behavior: SnackBarBehavior.floating,
                  margin:
                      const EdgeInsets.only(bottom: 90, left: 20, right: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                decoration: BoxDecoration(
                  color: count > 0
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: count > 0
                          ? kViolet.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.10),
                      offset: const Offset(0, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: count > 0
                            ? kPink.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.05),
                      ),
                      child: Center(
                        child: Text(
                          '⛔',
                          style: TextStyle(
                              fontSize: 20,
                              color: count > 0
                                  ? kPink
                                  : Colors.white.withValues(alpha: 0.4)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unblock All ($count)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: count > 0
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            count > 0
                                ? 'Tap to clear blocked songs list'
                                : 'No songs currently blocked',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.45),
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
        );
      },
    );
  }

  Widget _clearHistoryButton() {
    return Consumer<AppState>(
      builder: (context, appState, _) => GestureDetector(
        onTap: () async {
          final messenger = ScaffoldMessenger.of(context);
          final count = appState.history.length;
          if (count == 0) return;

          bool? confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text('Clear History',
                  style: TextStyle(color: Colors.white, fontFamily: 'serif')),
              content: const Text(
                  'Are you sure you want to delete all session history?',
                  style: TextStyle(color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white30)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Clear', style: TextStyle(color: kRed)),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await appState.clearHistory();
            messenger.showSnackBar(
              SnackBar(
                content: const Text('History cleared'),
                backgroundColor: kOrange.withValues(alpha: 0.8),
                behavior: SnackBarBehavior.floating,
              ),
            );
            // Redirect to Home
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MoodInputScreen()),
                  (route) => false);
            }
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        color: Colors.white54, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'Clear Session History',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
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

  Widget _clearPlayedHistoryButton() {
    return Consumer<AppState>(
      builder: (context, appState, _) => GestureDetector(
        onTap: () async {
          final messenger = ScaffoldMessenger.of(context);

          bool? confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text('Clear Played History',
                  style: TextStyle(color: Colors.white, fontFamily: 'serif')),
              content: const Text(
                  'This will permanently delete your played and skipped song history. Songs you\'ve heard before may appear again.',
                  style: TextStyle(color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white30)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Clear', style: TextStyle(color: kOrange)),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await appState.clearPlayedSongsHistory();
            messenger.showSnackBar(
              SnackBar(
                content: const Text('Played song history cleared'),
                backgroundColor: kOrange.withValues(alpha: 0.8),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_toggle_off_rounded,
                        color: Colors.white54, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'Clear Played History',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
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

  // ─── Logout button ────────────────────────────────────────────────────────────
  Widget _logoutButton() {
    return AnimatedBuilder(
      animation: _logoutPressCtrl,
      builder: (_, __) {
        final press = CurvedAnimation(
          parent: _logoutPressCtrl,
          curve: Curves.easeOut,
        ).value;
        return GestureDetector(
          onTapDown: (_) => _logoutPressCtrl.forward(),
          onTapUp: (_) async {
            _logoutPressCtrl.reverse();
            final appState = Provider.of<AppState>(context, listen: false);
            await appState.logout();
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const SplashScreen()),
              (route) => false,
            );
          },
          onTapCancel: () => _logoutPressCtrl.reverse(),
          child: Transform.scale(
            scale: _lerp(1.0, 0.97, press),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(
                          kRed.withValues(alpha: 0.18),
                          kRed.withValues(alpha: 0.36),
                          press,
                        )!,
                        Color.lerp(
                          const Color(0xFFEF4444).withValues(alpha: 0.12),
                          const Color(0xFFEF4444).withValues(alpha: 0.28),
                          press,
                        )!,
                      ],
                    ),
                    border: Border.all(
                      color: kRed.withValues(alpha: _lerp(0.30, 0.70, press)),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.08),
                        offset: const Offset(0, 2),
                        blurRadius: 0,
                      ),
                      BoxShadow(
                        color: kRed.withValues(alpha: _lerp(0.14, 0.40, press)),
                        blurRadius: _lerp(28, 48, press),
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
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(18),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x14FFFFFF), Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '🚪',
                              style: TextStyle(fontSize: _lerp(18, 20, press)),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Log Out',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(
                                  0xFFFCA5A5,
                                ).withValues(alpha: 0.92),
                                letterSpacing: 0.04 * 14,
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
    return Consumer<AppState>(
      builder: (_, appState, __) {
        final progress = appState.playbackProgress.clamp(0.0, 1.0);
        return GestureDetector(
          onTap: () {
            appState.openPlayer();
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
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF9A6B),
                          ),
                          minHeight: 2,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 14, 2),
                      child: Row(
                        children: [
                          AnimatedBuilder(
                            animation: _playerAlbumCtrl,
                            builder: (_, __) => Transform.rotate(
                              angle: appState.isPlaying
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
                                    color: Colors.white.withValues(alpha: 0.20),
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
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Builder(
                              builder: (_) {
                                final hasSongs = appState.songs.isNotEmpty;
                                final song = hasSongs
                                    ? appState.songs[appState.currentTrackIndex
                                        .clamp(0, appState.songs.length - 1)]
                                    : null;
                                final title = song?.title ?? 'No song playing';
                                final artist =
                                    song?.artist ?? 'Analyze your mood first';
                                final emoji = song?.emoji ?? '🎵';
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
                          if (appState.featureSkipSong) ...[
                            const SizedBox(width: 8),
                            _playerBtn(
                              icon: Icons.skip_previous_rounded,
                              onTap: () {
                                appState.previousTrack();
                              },
                              size: 22,
                            ),
                          ],
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
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
                                  Center(
                                    child: Icon(
                                      appState.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (appState.featureSkipSong) ...[
                            const SizedBox(width: 8),
                            _playerBtn(
                              icon: Icons.skip_next_rounded,
                              onTap: () {
                                appState.nextTrack();
                              },
                              size: 22,
                            ),
                          ],
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
                          } else if (i == 2) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HistoryScreen(),
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

  // ─── Version line ──────────────────────────────────────────────────────────────
  Widget _versionLine() {
    return Center(
      child: Text(
        'MOODUPLIFT v2.4.1 · Made with ♥',
        style: TextStyle(
          fontSize: 10,
          color: Colors.white.withValues(alpha: 0.18),
          letterSpacing: 0.10 * 10,
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
