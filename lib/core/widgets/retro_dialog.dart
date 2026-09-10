import 'package:flutter/material.dart';
import 'package:tape_88/core/theme/app_colors.dart';

class RetroDialog extends StatelessWidget {
  const RetroDialog({
    required this.title,
    required this.child,
    this.icon = Icons.video_library_outlined,
    this.actions = const [],
    super.key,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    child: Container(
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: AppColors.panelLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cyan.withValues(alpha: .55)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: .10),
            blurRadius: 20,
          ),
          const BoxShadow(
            color: Colors.black87,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              color: AppColors.black,
              child: Row(
                children: [
                  Icon(icon, size: 19, color: AppColors.amber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.amber,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const _SignalLight(),
                ],
              ),
            ),
            Container(height: 1, color: AppColors.cyan.withValues(alpha: .45)),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: child,
            ),
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions
                      .map(
                        (action) => Padding(
                          padding: const EdgeInsets.only(left: 9),
                          child: action,
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class RetroConfirmDialog extends StatelessWidget {
  const RetroConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'CANCEL',
    this.destructive = false,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) => RetroDialog(
    title: title,
    icon: destructive ? Icons.warning_amber : Icons.video_library_outlined,
    actions: [
      OutlinedButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text(cancelLabel),
      ),
      FilledButton(
        style: destructive
            ? FilledButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: AppColors.black,
              )
            : null,
        onPressed: () => Navigator.pop(context, true),
        child: Text(confirmLabel),
      ),
    ],
    child: Text(
      message,
      style: const TextStyle(
        color: AppColors.textWarm,
        fontFamily: 'sans-serif',
        height: 1.4,
      ),
    ),
  );
}

class RetroTextInputDialog extends StatefulWidget {
  const RetroTextInputDialog({
    required this.title,
    required this.confirmLabel,
    this.initialValue = '',
    this.hintText = 'Tape label',
    this.maxLength = 40,
    super.key,
  });

  final String title;
  final String confirmLabel;
  final String initialValue;
  final String hintText;
  final int maxLength;

  @override
  State<RetroTextInputDialog> createState() => _RetroTextInputDialogState();
}

class _RetroTextInputDialogState extends State<RetroTextInputDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  void _submit() {
    final value = _controller.text.trim();
    if (value.isNotEmpty) Navigator.pop(context, value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RetroDialog(
    title: widget.title,
    icon: Icons.edit_note,
    actions: [
      OutlinedButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('CANCEL'),
      ),
      FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
    ],
    child: TextField(
      controller: _controller,
      autofocus: true,
      maxLength: widget.maxLength,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _submit(),
      style: const TextStyle(color: AppColors.cyan),
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.chevron_right, color: AppColors.amber),
        filled: true,
        fillColor: AppColors.black,
      ),
    ),
  );
}

class _SignalLight extends StatelessWidget {
  const _SignalLight();

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: const BoxDecoration(
      color: AppColors.cyan,
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: AppColors.cyan, blurRadius: 7)],
    ),
  );
}
