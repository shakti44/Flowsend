import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Circular SVG-style progress ring for the active transfer screen.
/// Matches the Stitch active_transfer design with dual-ring and glow effect.
class TransferRing extends StatelessWidget {
  const TransferRing({
    super.key,
    required this.progress,
    this.size = 256,
    this.strokeWidth = 12,
    this.centerChild,
  });

  /// Progress from 0.0 to 1.0.
  final double progress;
  final double size;
  final double strokeWidth;
  final Widget? centerChild;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The ring itself
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
            ),
          ),

          // Center content (percentage + ETA)
          if (centerChild != null) centerChild!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.strokeWidth});

  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -90 * (3.14159 / 180); // -90° (top)
    final sweepAngle = 2 * 3.14159 * progress;

    // Track ring (background)
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = AppColors.surfaceContainerHigh.withValues(alpha: 0.5)
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc with gradient
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradientPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: 0,
        endAngle: 6.28318,
        colors: AppColors.transferRingGradient,
      ).createShader(rect);

    // Glow filter
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.8
      ..strokeCap = StrokeCap.round
      ..color = AppColors.secondaryContainer.withValues(alpha: 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    if (progress > 0) {
      canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);
      canvas.drawArc(rect, startAngle, sweepAngle, false, gradientPaint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
