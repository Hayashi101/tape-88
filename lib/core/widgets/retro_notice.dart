import 'package:flutter/material.dart';
import 'package:tape_88/core/theme/app_colors.dart';

enum RetroNoticeType { success, info, error }

void showRetroNotice(
  BuildContext context, {
  required String message,
  RetroNoticeType type = RetroNoticeType.info,
  Duration duration = const Duration(seconds: 2),
}) {
  final (label, icon, color) = switch (type) {
    RetroNoticeType.success => ('SIGNAL OK', Icons.check, AppColors.cyan),
    RetroNoticeType.info => ('DECK INFO', Icons.info_outline, AppColors.amber),
    RetroNoticeType.error => (
      'DECK ERROR',
      Icons.warning_amber,
      AppColors.coral,
    ),
  };
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        padding: EdgeInsets.zero,
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.black.withValues(alpha: .97),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: color.withValues(alpha: .72)),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: .14), blurRadius: 14),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withValues(alpha: .5)),
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontFamily: 'sans-serif',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: color, blurRadius: 6)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
}
