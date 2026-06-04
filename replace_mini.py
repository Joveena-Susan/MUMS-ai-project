import os

base_dir = r"c:\Users\jeffy\Downloads\ui_flutter\lib"
files_to_update = [
    "mood_input.dart",
    "next_target.dart",
    "mooduplift_history.dart",
    "settings.dart"
]

new_mini_player = """  Widget _miniPlayer(double W) {
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
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(color: Colors.white.withOpacity(0.14)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.12),
                        offset: const Offset(0, 1),
                        blurRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.30),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: const Color(0xFFFF9A6B).withOpacity(0.06),
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
                            backgroundColor: Colors.white.withOpacity(0.08),
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
                                      color: Colors.white.withOpacity(0.20),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF9A6B).withOpacity(0.25),
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
                                      ? appState.songs[appState
                                          .currentTrackIndex
                                          .clamp(0, appState.songs.length - 1)]
                                      : null;
                                  final title = song?.title ?? 'No song playing';
                                  final artist = song?.artist ?? 'Analyze your mood first';
                                  final emoji = song?.emoji ?? '🎵';
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
                                          color: Colors.white.withOpacity(0.50),
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
                            _playerBtn(
                              icon: Icons.skip_previous_rounded,
                              onTap: () {
                                appState.previousTrack();
                              },
                              size: 22,
                            ),
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
                                      const Color(0xFFFF9A6B).withOpacity(0.35),
                                      const Color(0xFFE48DFF).withOpacity(0.25),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFFFF9A6B).withOpacity(0.50),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.20),
                                      offset: const Offset(0, 1),
                                      blurRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFFFF9A6B).withOpacity(0.25),
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
                            const SizedBox(width: 8),
                            _playerBtn(
                              icon: Icons.skip_next_rounded,
                              onTap: () {
                                appState.nextTrack();
                              },
                              size: 22,
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
  }"""

def replace_method(content, method_signature, replacement):
    start_idx = content.find(method_signature)
    if start_idx == -1:
        return content, False
    
    # Find matching closing brace
    brace_count = 0
    in_method = False
    
    for i in range(start_idx, len(content)):
        if content[i] == '{':
            brace_count += 1
            in_method = True
        elif content[i] == '}':
            brace_count -= 1
            
        if in_method and brace_count == 0:
            end_idx = i + 1
            return content[:start_idx] + replacement + content[end_idx:], True
            
    return content, False

for filename in files_to_update:
    path = os.path.join(base_dir, filename)
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    new_content, replaced = replace_method(content, "  Widget _miniPlayer(double W) {", new_mini_player)
    
    if replaced:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {filename}")
    else:
        print(f"Could not find or replace in {filename}")

print("Done")
