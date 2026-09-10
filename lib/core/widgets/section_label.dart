import 'package:flutter/material.dart';
import 'package:tape_88/core/theme/app_colors.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {this.color = AppColors.amber, super.key});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(Icons.graphic_eq, size: 16, color: color),
      const SizedBox(width: 7),
      Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.3,
          color: AppColors.textWarm,
        ),
      ),
    ],
  );
}
