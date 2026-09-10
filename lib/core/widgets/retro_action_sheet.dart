import 'package:flutter/material.dart';
import 'package:tape_88/core/theme/app_colors.dart';

class RetroActionItem<T> {
  const RetroActionItem({
    required this.value,
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final T value;
  final IconData icon;
  final String label;
  final bool destructive;
}

Future<T?> showRetroActionSheet<T>({
  required BuildContext context,
  required String title,
  required String subject,
  required List<RetroActionItem<T>> actions,
}) => showModalBottomSheet<T>(
  context: context,
  backgroundColor: Colors.transparent,
  showDragHandle: false,
  builder: (sheetContext) => SafeArea(
    child: Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.panelLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cyan.withValues(alpha: .5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: .08),
            blurRadius: 18,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: AppColors.black,
              padding: const EdgeInsets.fromLTRB(16, 9, 8, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.settings_input_component,
                    size: 18,
                    color: AppColors.amber,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.amber,
                            fontSize: 9,
                            letterSpacing: 1.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'sans-serif',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close, color: AppColors.cyan),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: AppColors.cyan.withValues(alpha: .42)),
            ...actions.indexed.expand((entry) sync* {
              final action = entry.$2;
              final color = action.destructive
                  ? AppColors.coral
                  : entry.$1.isEven
                  ? AppColors.cyan
                  : AppColors.amberSoft;
              yield ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                leading: Icon(action.icon, color: color),
                title: Text(
                  action.label,
                  style: TextStyle(
                    color: action.destructive
                        ? AppColors.coral
                        : AppColors.text,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .4,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: color.withValues(alpha: .8),
                ),
                onTap: () => Navigator.pop(sheetContext, action.value),
              );
              if (entry.$1 < actions.length - 1) {
                yield const Divider(height: 1, color: Color(0x334FDBCC));
              }
            }),
          ],
        ),
      ),
    ),
  ),
);
