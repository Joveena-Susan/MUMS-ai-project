import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'mooduplift_splash.dart';
import 'player_and_feedback.dart';
import 'mood_input.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Load persisted state before first frame
  final appState = AppState();
  await appState.loadFromPrefs();

  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: const MoodUpliftRoot(),
    ),
  );
}

class MoodUpliftRoot extends StatelessWidget {
  const MoodUpliftRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Mood Uplift',
      debugShowCheckedModeBanner: false,
      navigatorKey: AppState.navigatorKey,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF000000),
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF000000),
        ),
      ),
      // Return the Stack with an app-level overlay
      builder: (context, child) {
        return Scaffold(
          body: Consumer<AppState>(
            builder: (context, appState, _) {
              final isOpen = appState.isPlayerOpen;
              final h = MediaQuery.of(context).size.height;
              return Stack(
                children: [
                  if (child != null) TickerMode(enabled: !isOpen, child: child),
                  if (appState.songs.isNotEmpty)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      top: isOpen ? 0 : h,
                      left: 0,
                      right: 0,
                      height: h,
                      child: const PlayerScreen(),
                    ),
                ],
              );
            },
          ),
        );
      },
      // Start at mood-input if logged in, otherwise splash
      home: Consumer<AppState>(
        builder: (context, appState, _) {
          return appState.isLoggedIn
              ? const MoodInputScreen()
              : const SplashScreen();
        },
      ),
    );
  }
}
