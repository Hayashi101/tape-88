import 'package:flutter/material.dart';

/// A static, touch-through CRT finish. It paints once per viewport size and
/// intentionally contains no animation so scrolling and artwork stay smooth.
class RetroScreenOverlay extends StatelessWidget {
  const RetroScreenOverlay({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      child,
      const Positioned.fill(
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: RepaintBoundary(child: CustomPaint(painter: _CrtPainter())),
          ),
        ),
      ),
    ],
  );
}

class _CrtPainter extends CustomPainter {
  const _CrtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scanline = Paint()
      ..color = const Color(0x0A000000)
      ..strokeWidth = 1;
    for (double y = .5; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanline);
    }

    final vignette = Paint()
      ..shader = const RadialGradient(
        radius: .82,
        colors: [Color(0x00000000), Color(0x05000000), Color(0x26000000)],
        stops: [0, .68, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x1450DCCC);
    canvas.drawRect(Offset.zero & size, edge);
  }

  @override
  bool shouldRepaint(covariant _CrtPainter oldDelegate) => false;
}
