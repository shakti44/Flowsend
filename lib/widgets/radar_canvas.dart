import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Animated radar discovery canvas — matches the Stitch "Choose Device" design.
/// Shows concentric SVG rings with pulsing/ping animations.
class RadarCanvas extends StatefulWidget {
  const RadarCanvas({super.key, this.size = 144, this.isActive = true});

  final double size;
  final bool isActive;

  @override
  State<RadarCanvas> createState() => _RadarCanvasState();
}

class _RadarCanvasState extends State<RadarCanvas>
    with TickerProviderStateMixin {
  late final AnimationController _pingController;
  late final AnimationController _pulseController;
  late final Animation<double> _pingAnim;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pingAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pingController, curve: Curves.easeOut),
    );
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // SVG concentric rings
          CustomPaint(
            size: Size(s, s),
            painter: _RadarRingsPainter(),
          ),

          // Ping ripple animation
          AnimatedBuilder(
            animation: _pingAnim,
            builder: (context, _) {
              final scale = 0.7 + _pingAnim.value * 0.3;
              final opacity = (1.0 - _pingAnim.value) * 0.4;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: s,
                  height: s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondaryContainer.withValues(alpha: opacity),
                  ),
                ),
              );
            },
          ),

          // Inner pulse
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, _) {
              return Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  width: s * 0.56,
                  height: s * 0.56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryContainer.withValues(alpha: 0.20),
                  ),
                ),
              );
            },
          ),

          // Center node
          Container(
            width: s * 0.39,
            height: s * 0.39,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryContainer,
                  AppColors.secondaryContainer,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.45),
                  blurRadius: 24,
                  spreadRadius: -2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainerLowest,
              ),
              child: const Icon(
                Icons.sensors,
                color: AppColors.secondary,
                size: 22,
              ),
            ),
          ),

          // Orbiting detection pip — top-right
          Positioned(
            top: s * 0.14,
            right: s * 0.21,
            child: _BouncePip(color: AppColors.secondary, size: 10),
          ),

          // Orbiting detection pip — bottom-left
          Positioned(
            bottom: s * 0.28,
            left: s * 0.28,
            child: _StaticPip(color: AppColors.primary, size: 8),
          ),
        ],
      ),
    );
  }
}

class _RadarRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Outer dashed ring
    ringPaint.color = AppColors.secondaryContainer.withValues(alpha: 0.10);
    _drawCircle(canvas, center, maxR * 0.916, ringPaint, dashed: true);

    // Mid ring
    ringPaint.color = AppColors.secondaryContainer.withValues(alpha: 0.20);
    ringPaint.strokeWidth = 1.2;
    _drawCircle(canvas, center, maxR * 0.639, ringPaint);

    // Inner ring
    ringPaint.color = AppColors.secondaryContainer.withValues(alpha: 0.35);
    _drawCircle(canvas, center, maxR * 0.361, ringPaint);
  }

  void _drawCircle(Canvas canvas, Offset center, double radius, Paint paint,
      {bool dashed = false}) {
    if (!dashed) {
      canvas.drawCircle(center, radius, paint);
      return;
    }
    // Approximate dashed circle with short arcs
    const dashAngle = 0.08;
    const gapAngle = 0.08;
    double angle = 0;
    while (angle < 2 * 3.14159) {
      final path = Path()
        ..addArc(
          Rect.fromCircle(center: center, radius: radius),
          angle,
          dashAngle,
        );
      canvas.drawPath(path, paint);
      angle += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(_RadarRingsPainter old) => false;
}

class _BouncePip extends StatefulWidget {
  const _BouncePip({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  State<_BouncePip> createState() => _BouncePipState();
}

class _BouncePipState extends State<_BouncePip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0, end: -4).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _a.value),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.8),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaticPip extends StatelessWidget {
  const _StaticPip({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.7),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }
}
