import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tape_88/core/theme/app_colors.dart';

class VuMeter extends StatefulWidget {
  const VuMeter({required this.active, super.key});
  final bool active;
  @override
  State<VuMeter> createState() => _VuMeterState();
}

class _VuMeterState extends State<VuMeter> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(VuMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.repeat();
    } else if (!widget.active && oldWidget.active) {
      _controller
        ..stop()
        ..animateTo(0, duration: const Duration(milliseconds: 180));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (_, _) => Row(
      children: List.generate(12, (index) {
        final phase = _controller.value * math.pi * 8;
        final primary = (math.sin(phase + index * .37) + 1) / 2;
        final secondary = (math.sin(phase * 1.73 + index * 1.11) + 1) / 2;
        final level = .28 + primary * .42 + secondary * .22;
        final lit = widget.active && index / 12 < level;
        final color = index > 9
            ? AppColors.coral
            : (index > 6 ? AppColors.amber : AppColors.cyan);
        return Expanded(
          child: Container(
            height: 5 + index * .5,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: lit ? color : AppColors.panelHighest,
              boxShadow: lit
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: .3),
                        blurRadius: 3,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    ),
  );
}
