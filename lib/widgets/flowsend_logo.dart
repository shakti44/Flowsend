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
    final bgPaint = Paint()..color = const Color(0xFF071126);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(w * 0.24)),
      bgPaint,
    );

    final borderPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(w * 0.018), Radius.circular(w * 0.22)),
      borderPaint,
    );

    final markPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final flowPath = Path()
      ..moveTo(w * 0.24, h * 0.62)
      ..cubicTo(w * 0.32, h * 0.78, w * 0.48, h * 0.78, w * 0.57, h * 0.57)
      ..cubicTo(w * 0.66, h * 0.36, w * 0.81, h * 0.36, w * 0.78, h * 0.55);
    canvas.drawPath(flowPath, markPaint);
    canvas.drawCircle(Offset(w * 0.24, h * 0.62), w * 0.10, markPaint);
    canvas.drawCircle(Offset(w * 0.78, h * 0.55), w * 0.10, markPaint);
    final arrow = Path()
      ..moveTo(w * 0.47, h * 0.48)
      ..lineTo(w * 0.62, h * 0.48)
      ..lineTo(w * 0.55, h * 0.40);
    canvas.drawPath(arrow, markPaint);
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
