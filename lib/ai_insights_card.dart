import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

const Color _kOrange = Color(0xFFFB923C);
const Color _kPink = Color(0xFFF472B6);
const Color _kViolet = Color(0xFFC4B5FD);
const Color _kGreen = Color(0xFFA7F3D0);

/// A glassmorphic card that displays AI-generated emotional insights
/// about the user's mood patterns. Data comes from AppState.aiInsights.
class AiInsightsCard extends StatefulWidget {
  const AiInsightsCard({super.key});

  @override
  State<AiInsightsCard> createState() => _AiInsightsCardState();
}

class _AiInsightsCardState extends State<AiInsightsCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final loading = appState.aiInsightsLoading;
        final insights = appState.aiInsights;

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _kViolet.withValues(alpha: 0.10),
                    _kPink.withValues(alpha: 0.06),
                    Colors.white.withValues(alpha: 0.04),
                  ],
                ),
                border: Border.all(
                  color: _kViolet.withValues(alpha: 0.22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kViolet.withValues(alpha: 0.12),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────
                  Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [_kViolet, _kPink],
                        ).createShader(b),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [_kViolet, _kPink],
                        ).createShader(b),
                        child: const Text(
                          'AI INSIGHTS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: _kViolet.withValues(alpha: 0.12),
                          border: Border.all(
                              color: _kViolet.withValues(alpha: 0.24)),
                        ),
                        child: Text(
                          'Personalised',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            color: _kViolet.withValues(alpha: 0.90),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Color(0x1AFFFFFF), height: 1),
                  const SizedBox(height: 14),

                  // ── Content ─────────────────────────────────────
                  if (loading)
                    ..._buildShimmerRows()
                  else if (insights.isEmpty)
                    _buildEmptyState()
                  else
                    Column(
                      children: insights.asMap().entries.map((entry) {
                        return _buildInsightRow(entry.key, entry.value);
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInsightRow(int index, String text) {
    final colors = [_kViolet, _kPink, _kOrange, _kGreen];
    final color = colors[index % colors.length];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
              ],
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.82),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.music_note_rounded,
              size: 16, color: _kViolet.withValues(alpha: 0.45)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Complete a few sessions so I can learn your mood patterns.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Colors.white.withValues(alpha: 0.45),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildShimmerRows() {
    return List.generate(
      3,
      (i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AnimatedBuilder(
          animation: _shimmerCtrl,
          builder: (_, __) {
            final t = _shimmerCtrl.value;
            return Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 10, top: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 12,
                    margin: EdgeInsets.only(right: (i == 2 ? 60 : 0)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.07),
                          Colors.white.withValues(alpha: 0.14 * t + 0.07),
                          Colors.white.withValues(alpha: 0.07),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
