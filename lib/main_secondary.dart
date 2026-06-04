import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MoodMusicApp());
}

class MoodMusicApp extends StatelessWidget {
  const MoodMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), 
      home: const SpotifyEmbedScreen(),
    );
  }
}

class SpotifyEmbedScreen extends StatefulWidget {
  const SpotifyEmbedScreen({super.key});

  @override
  State<SpotifyEmbedScreen> createState() => _SpotifyEmbedScreenState();
}

class _SpotifyEmbedScreenState extends State<SpotifyEmbedScreen> {
  late final WebViewController _controller;
  String selectedMood = "Happy";
  bool isLoginMode = false; 

  // --- 1. REAL SPOTIFY EMBED URLS ---
  // We use the 'embed' version of the links to ensure the UI looks good.
  final Map<String, String> moodUrls = {
    "Happy": "https://open.spotify.com/embed/track/3Bq7CnWgfvplEzGSVXUvOe?utm_source=generator", // Happy - Pharrell
    "Sad": "https://open.spotify.com/embed/track/4kflIGfjdZJW4ot2ioixTB",   // Someone Like You
    "Relaxed": "https://open.spotify.com/embed/track/6kkwzB6hXLIONkEk9JciA6", // Weightless
    "Energetic": "https://open.spotify.com/embed/track/2KH16WveQVOLQS45tQQRnz", // Eye of the Tiger
  };

  @override
  void initState() {
    super.initState();
    
    // --- 2. INITIALIZE WEBVIEW WITH THE FIX ---
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      
      // 🛠️ THE FIX: Set User Agent to look like Chrome on Android
      // This prevents the "Playback disabled / Browser not supported" error
      ..setUserAgent("Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36")
      
      ..setBackgroundColor(const Color(0xFF121212)) // Dark background
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // Allow all navigation so login works
            return NavigationDecision.navigate;
          },
        ),
      );

    // Load the initial player
    _loadHtmlForMood("Happy");
  }

  // --- 3. LOAD THE PLAYER (HTML Injection) ---
  void _loadHtmlForMood(String mood) {
    final String spotifyUrl = moodUrls[mood]!;

    String htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { margin: 0; background-color: #121212; display: flex; justify-content: center; align-items: center; height: 100vh; }
          iframe { border-radius: 12px; border: none; box-shadow: 0 4px 15px rgba(0,0,0,0.5); }
        </style>
      </head>
      <body>
        <iframe 
          src="$spotifyUrl" 
          width="100%" 
          height="352" 
          frameBorder="0" 
          allowfullscreen="" 
          allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture" 
          loading="lazy">
        </iframe>
      </body>
      </html>
    ''';

    _controller.loadHtmlString(htmlContent);
    setState(() {
      isLoginMode = false;
    });
  }

  // --- 4. LOAD LOGIN PAGE ---
  void _loadLoginPage() {
    // Load the OFFICIAL Spotify Login Page
    _controller.loadRequest(Uri.parse("https://accounts.spotify.com/en/login"));
    
    setState(() {
      isLoginMode = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Log in securely. Press 'Back to Player' when done!"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(isLoginMode ? "🔐 Secure Login" : "🎧 Mood Player"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // LOGIN BUTTON (Key Icon) - Only show if NOT logging in
          if (!isLoginMode)
            IconButton(
              icon: const Icon(Icons.vpn_key, color: Colors.green),
              tooltip: "Log In to Spotify",
              onPressed: _loadLoginPage,
            ),

          // BACK TO PLAYER BUTTON - Only show IF logging in
          if (isLoginMode)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, 
                  foregroundColor: Colors.white
                ),
                icon: const Icon(Icons.music_note),
                label: const Text("Back to Player"),
                onPressed: () {
                  // Reload the player (now with cookies!)
                  _loadHtmlForMood(selectedMood);
                },
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // DROPDOWN - Hide during login
            if (!isLoginMode) ...[
              const Text("Select your Vibe:", style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 10),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedMood,
                    isExpanded: true,
                    dropdownColor: Colors.grey[800],
                    items: moodUrls.keys.map((String mood) {
                      return DropdownMenuItem<String>(
                        value: mood,
                        child: Text(mood, style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedMood = newValue;
                        });
                        _loadHtmlForMood(newValue);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // THE WEBVIEW CONTAINER
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: WebViewWidget(controller: _controller),
              ),
            ),
            
            // Helper Text
            if (isLoginMode)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  "Enter your Spotify credentials above.\nYour password goes directly to Spotify.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}