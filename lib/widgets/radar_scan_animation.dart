import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RadarScanAnimation extends StatefulWidget {
  final bool isScanning;
  final double size;

  const RadarScanAnimation({
    super.key,
    required this.isScanning,
    this.size = 200,
  });

  @override
  State<RadarScanAnimation> createState() => _RadarScanAnimationState();
}

class _RadarScanAnimationState extends State<RadarScanAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.isScanning) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(RadarScanAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isScanning && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _RadarPainter(
              angle: _controller.value * 2 * math.pi,
              isScanning: widget.isScanning,
            ),
            child: Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.2),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const Icon(
                  Icons.wifi_tethering,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double angle;
  final bool isScanning;

  _RadarPainter({required this.angle, required this.isScanning});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw concentric circles
    final ringPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * (i / 3), ringPaint);
    }

    // Draw crosshair axes
    final axisPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.1)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), axisPaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), axisPaint);

    if (isScanning) {
      // Draw radar sweep cone
      final sweepPaint = Paint()
        ..shader = SweepGradient(
          center: Alignment.center,
          startAngle: 0.0,
          endAngle: math.pi / 2,
          colors: [
            AppColors.primary.withOpacity(0.35),
            AppColors.primary.withOpacity(0.0),
          ],
          transform: GradientRotation(angle),
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawCircle(center, radius, sweepPaint);

      // Draw leading sweep ray
      final rayPaint = Paint()
        ..color = AppColors.primary
        ..strokeWidth = 2.0;

      final rayEnd = Offset(
        center.dx + radius * math.cos(angle + math.pi / 2),
        center.dy + radius * math.sin(angle + math.pi / 2),
      );
      canvas.drawLine(center, rayEnd, rayPaint);
    }
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.isScanning != isScanning;
  }
}
