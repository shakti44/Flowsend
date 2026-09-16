import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// FlowSend SVG logo — phone→laptop stream with brand gradient.
/// Rendered as a Flutter CustomPaint to avoid asset loading.
class FlowSendLogo extends StatelessWidget {
  const FlowSendLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoPainter(),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    const gradient = LinearGradient(
      begin: Alignment(-0.8, -0.8),
      end: Alignment(0.8, 0.8),
      colors: AppColors.brandGradient,
    );

    final rect = Rect.fromLTWH(0, 0, w, h);
    final gradientPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.035;

    // Background rounded square
    final bgPaint = Paint()
      ..color = const Color(0xFF0A0F1D)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(w * 0.24)),
      bgPaint,
    );

    // Border stroke with gradient
    final borderPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.015
      ..color = AppColors.primaryContainer.withValues(alpha: 0.3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(w * 0.015),
        Radius.circular(w * 0.225),
      ),
      borderPaint,
    );

    // Phone node (circle at bottom-left)
    final phonePaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035;
    canvas.drawCircle(Offset(w * 0.28, h * 0.62), w * 0.10, phonePaint);

    // Phone center dot
    final dotPaint = Paint()
      ..color = AppColors.secondaryContainer
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.28, h * 0.62), w * 0.04, dotPaint);

    // Laptop node (rect at top-right)
    final laptopRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.62, h * 0.26, w * 0.18, h * 0.26),
      const Radius.circular(4),
    );
    canvas.drawRRect(laptopRect, gradientPaint);

    // Laptop dot
    final laptopDotPaint = Paint()
      ..color = AppColors.tertiaryContainer
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.71, h * 0.46), w * 0.015, laptopDotPaint);

    // Dashed arc stream (phone → laptop)
    final streamPath = Path()
      ..moveTo(w * 0.34, h * 0.56)
      ..cubicTo(w * 0.42, h * 0.42, w * 0.54, h * 0.36, w * 0.62, h * 0.36);

    // Draw dashed path
    _drawDashedPath(canvas, streamPath, gradientPaint, w * 0.035, 3, 3);

    // Arrow head
    final arrowPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = w * 0.035;
    final arrowPath = Path()
      ..moveTo(w * 0.56, h * 0.31)
      ..lineTo(w * 0.65, h * 0.36)
      ..lineTo(w * 0.57, h * 0.42);
    canvas.drawPath(arrowPath, arrowPaint);
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    double strokeWidth,
    double dashLength,
    double gapLength,
  ) {
    final dashPaint = Paint()
      ..shader = paint.shader
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final start = distance;
        final end = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(start, end), dashPaint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_LogoPainter old) => false;
}

/// Glowing circular container for the logo — used on the home screen radar.
class FlowSendLogoOrb extends StatefulWidget {
  const FlowSendLogoOrb({super.key, this.size = 96});
  final double size;

  @override
  State<FlowSendLogoOrb> createState() => _FlowSendLogoOrbState();
}

class _FlowSendLogoOrbState extends State<FlowSendLogoOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.9, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surfaceContainerHigh,
                AppColors.surfaceContainer,
                AppColors.surfaceContainerHighest,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondaryContainer.withValues(alpha: 0.35),
                blurRadius: 32,
                spreadRadius: -4,
              ),
            ],
          ),
          padding: const EdgeInsets.all(1),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainerLowest,
            ),
            padding: EdgeInsets.all(widget.size * 0.14),
            child: FlowSendLogo(size: widget.size * 0.72),
          ),
        );
      },
    );
  }
}
