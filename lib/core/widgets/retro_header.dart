import 'package:flutter/material.dart';
import 'package:tape_88/core/theme/app_colors.dart';

class RetroHeader extends StatelessWidget implements PreferredSizeWidget {
  const RetroHeader({this.compact = false, super.key});
  final bool compact;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    titleSpacing: 16,
    title: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: AppColors.panelHighest),
          ),
          padding: const EdgeInsets.all(3),
          child: Image.asset(
            'assets/branding/tape_88_logo_foreground.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(compact ? 'TAPE88' : 'RETROTAPE'),
          ),
        ),
      ],
    ),
    actions: [
      const Center(
        child: Text(
          '● LOCAL',
          style: TextStyle(
            color: AppColors.amber,
            fontSize: 11,
            letterSpacing: 1.4,
          ),
        ),
      ),
      const SizedBox(width: 18),
    ],
  );
}
