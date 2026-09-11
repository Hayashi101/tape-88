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
    titleSpacing: 12,
    title: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          padding: const EdgeInsets.all(0),
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
            child: ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  colors: [
                    Color(0xFF00F5FF), // cyan
                    Color(0xFF0066FF), // electric blue
                    Color(0xFF7B2CFF), // purple
                    Color(0xFFFF2DAA), // hot pink
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(bounds);
              },
              child: Text(compact ? 'TAPE88' : 'RETROTAPE'),
            ),
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
