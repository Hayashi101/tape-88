import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tape_88/core/theme/app_colors.dart';
import 'package:tape_88/features/library/domain/entities/track.dart';
import 'package:tape_88/features/library/domain/entities/tape_profile.dart';

class CassetteDeck extends StatefulWidget {
  const CassetteDeck({
    required this.track,
    required this.isPlaying,
    required this.progress,
    super.key,
  });
  final Track track;
  final bool isPlaying;
  final double progress;

  @override
  State<CassetteDeck> createState() => _CassetteDeckState();
}

class _CassetteDeckState extends State<CassetteDeck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reels = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isPlaying) _reels.repeat();
  }

  @override
  void didUpdateWidget(CassetteDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_reels.isAnimating) _reels.repeat();
    if (!widget.isPlaying && _reels.isAnimating) _reels.stop();
  }

  @override
  void dispose() {
    _reels.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.55,
    child: AnimatedBuilder(
      animation: _reels,
      builder: (context, _) => CustomPaint(
        painter: _CassettePainter(
          angle: _reels.value * math.pi * 2,
          progress: widget.progress.clamp(0, 1),
          title: widget.track.title,
          artist: widget.track.artist,
          tapeLabel: widget.track.tapeProfile.fullLabel,
        ),
      ),
    ),
  );
}

class _CassettePainter extends CustomPainter {
  const _CassettePainter({
    required this.angle,
    required this.progress,
    required this.title,
    required this.artist,
    required this.tapeLabel,
  });
  final double angle;
  final double progress;
  final String title;
  final String artist;
  final String tapeLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 360;
    final sy = size.height / 232;
    canvas.save();
    canvas.scale(sx, sy);
    final shell = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 360, 232),
      const Radius.circular(14),
    );
    canvas.drawRRect(
      shell,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF38393C), Color(0xFF292A2D)],
        ).createShader(shell.outerRect),
    );
    canvas.drawRRect(
      shell,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: .1),
    );

    _screw(canvas, const Offset(20, 20));
    _screw(canvas, const Offset(340, 20));
    _screw(canvas, const Offset(20, 212));
    _screw(canvas, const Offset(340, 212));

    final label = RRect.fromRectAndRadius(
      const Rect.fromLTWH(16, 30, 328, 160),
      const Radius.circular(8),
    );
    canvas.drawRRect(label, Paint()..color = AppColors.black);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(26, 40, 308, 50),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFF0D6BA),
    );
    _text(
      canvas,
      'VIRTUAL SIDE A  •  $tapeLabel',
      const Offset(36, 45),
      6.5,
      const Color(0xFF6A4B32),
      FontWeight.w700,
    );
    _fittedText(
      canvas,
      title.toUpperCase(),
      const Offset(36, 56),
      maxWidth: 288,
      maxSize: 14,
      minSize: 8.5,
      color: const Color(0xFF39200B),
      weight: FontWeight.w700,
    );
    _text(
      canvas,
      artist,
      const Offset(36, 76),
      8.5,
      const Color(0xFF6A4B32),
      FontWeight.w600,
    );

    final window = RRect.fromRectAndRadius(
      const Rect.fromLTWH(40, 103, 280, 62),
      const Radius.circular(5),
    );
    canvas.drawRRect(window, Paint()..color = const Color(0xFF17181C));
    canvas.drawRect(
      const Rect.fromLTWH(68, 129, 224, 9),
      Paint()..color = const Color(0xFF553719),
    );
    _reel(canvas, const Offset(96, 134), 25 + (1 - progress) * 9, angle);
    _reel(canvas, const Offset(264, 134), 25 + progress * 9, angle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(150, 116, 60, 35),
        const Radius.circular(3),
      ),
      Paint()..color = AppColors.black,
    );
    _text(
      canvas,
      (progress * 999).round().toString().padLeft(3, '0'),
      const Offset(162, 124),
      17,
      AppColors.amberSoft,
      FontWeight.w500,
    );

    canvas.drawPath(
      Path()
        ..moveTo(105, 184)
        ..lineTo(255, 184)
        ..lineTo(275, 218)
        ..lineTo(85, 218)
        ..close(),
      Paint()..color = const Color(0xFF18191D),
    );
    for (final x in [128.0, 156.0, 204.0, 232.0]) {
      canvas.drawCircle(
        Offset(x, 203),
        4,
        Paint()..color = AppColors.panelHighest,
      );
    }
    canvas.restore();
  }

  void _screw(Canvas c, Offset p) {
    c.drawCircle(p, 6, Paint()..color = AppColors.black);
    c.drawRect(
      Rect.fromCenter(center: p, width: 8, height: 2),
      Paint()..color = AppColors.panelHighest,
    );
  }

  void _reel(Canvas c, Offset center, double radius, double spin) {
    c.drawCircle(center, radius, Paint()..color = const Color(0xFF594936));
    c.drawCircle(center, 18, Paint()..color = const Color(0xFF303338));
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(spin);
    final p = Paint()
      ..color = AppColors.black
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      c.rotate(math.pi / 3);
      c.drawLine(const Offset(0, 3), const Offset(0, 15), p);
    }
    c.restore();
  }

  void _text(
    Canvas c,
    String text,
    Offset offset,
    double size,
    Color color,
    FontWeight weight,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: size,
          color: color,
          fontWeight: weight,
          letterSpacing: .6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, offset);
  }

  void _fittedText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double maxWidth,
    required double maxSize,
    required double minSize,
    required Color color,
    required FontWeight weight,
  }) {
    var fontSize = maxSize;
    late TextPainter painter;
    do {
      painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: fontSize,
            color: color,
            fontWeight: weight,
            letterSpacing: .45,
          ),
        ),
        maxLines: 1,
        ellipsis: '…',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);
      if (!painter.didExceedMaxLines) break;
      fontSize -= .5;
    } while (fontSize >= minSize);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_CassettePainter old) =>
      angle != old.angle ||
      progress != old.progress ||
      title != old.title ||
      artist != old.artist ||
      tapeLabel != old.tapeLabel;
}
