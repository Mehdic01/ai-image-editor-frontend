import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// A modern, attractive full-screen loading overlay with glassmorphism style.
class LoadingOverlay extends StatefulWidget {
  final String title;
  final String subtitle;

  const LoadingOverlay({
    super.key,
    this.title = 'Generating your image',
    this.subtitle = 'This may take a few seconds',
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      ignoring: false,
      child: Stack(
        children: [
          // Soft gradient background
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      isDark
                          ? [
                            const Color(0xFF0F1115).withOpacity(0.92),
                            const Color(0xFF161A22).withOpacity(0.92),
                          ]
                          : [
                            const Color(0xFFFFFFFF).withOpacity(0.92),
                            const Color(0xFFF6F7FB).withOpacity(0.92),
                          ],
                ),
              ),
            ),
          ),

          // Decorative gradient blobs
          Positioned(
            top: -60,
            left: -40,
            child: _Blob(size: 180, color: Colors.tealAccent.withOpacity(0.35)),
          ),
          Positioned(
            bottom: -80,
            right: -40,
            child: _Blob(
              size: 220,
              color: Colors.purpleAccent.withOpacity(0.28),
            ),
          ),

          // Glass card with progress
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 24,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 260,
                    maxWidth: 420,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.white).withOpacity(
                      isDark ? 0.06 : 0.75,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: (isDark ? Colors.white70 : Colors.white)
                          .withOpacity(isDark ? 0.15 : 0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                        blurRadius: 28,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: AnimatedBuilder(
                    animation: _ctl,
                    builder: (context, _) {
                      final phase = (_ctl.value * 3).floor() % 4; // 0..3
                      final dots = ''.padRight(phase, '.');
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Animated ring
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDark ? Colors.tealAccent : Colors.black87,
                              ),
                              backgroundColor:
                                  (isDark ? Colors.white24 : Colors.black12),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${widget.title}$dots',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              minHeight: 5,
                              backgroundColor:
                                  isDark ? Colors.white10 : Colors.black12,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDark ? Colors.tealAccent : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withOpacity(0.0)]),
        ),
      ),
    );
  }
}
