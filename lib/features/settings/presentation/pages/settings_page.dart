import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tape_88/core/theme/app_colors.dart';
import 'package:tape_88/core/widgets/retro_header.dart';
import 'package:tape_88/core/widgets/retro_panel.dart';
import 'package:tape_88/core/widgets/retro_notice.dart';
import 'package:tape_88/core/widgets/section_label.dart';
import 'package:tape_88/features/library/presentation/controllers/library_controller.dart';
import 'package:tape_88/features/player/presentation/controllers/player_controller.dart';
import 'package:tape_88/features/settings/presentation/controllers/settings_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.controller,
    required this.libraryController,
    required this.settingsController,
    super.key,
  });

  final PlayerController controller;
  final LibraryController libraryController;
  final SettingsController settingsController;

  Future<void> _setVolume(double value) async {
    await controller.setVolume(value);
    await settingsController.setVolume(value);
  }

  Future<void> _setEqualizerPreset(BuildContext context, String preset) async {
    final result = await controller.setEqualizerPreset(preset);
    if (!context.mounted) return;
    await result.fold(
      onSuccess: (_) async {
        await settingsController.setEqualizerPreset(preset);
        if (!context.mounted) return;
        showRetroNotice(
          context,
          message: 'EQ PRESET • ${preset.toUpperCase()}',
          type: RetroNoticeType.success,
        );
      },
      onFailure: (failure) async {
        showRetroNotice(
          context,
          message: failure.message,
          type: RetroNoticeType.error,
        );
      },
    );
  }

  Future<void> _chooseEqualizerPreset(BuildContext context) async {
    if (!Platform.isAndroid) return;
    final preset = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.background,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ANALOG EQ PRESETS',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 10,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'OUTPUT CHARACTER',
                style: TextStyle(
                  fontFamily: 'sans-serif',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              RetroPanel(
                padding: EdgeInsets.zero,
                child: Column(
                  children: _EqPreset.values.indexed
                      .map((entry) {
                        final preset = entry.$2;
                        final selected =
                            settingsController.equalizerPreset == preset.label;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              onTap: () =>
                                  Navigator.pop(sheetContext, preset.label),
                              leading: _EqCurve(values: preset.curve),
                              title: Text(
                                preset.label.toUpperCase(),
                                style: TextStyle(
                                  color: selected
                                      ? AppColors.amber
                                      : AppColors.text,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                preset.description,
                                style: _subtitleStyle,
                              ),
                              trailing: Icon(
                                selected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: selected
                                    ? AppColors.cyan
                                    : AppColors.outlineDark,
                              ),
                            ),
                            if (entry.$1 < _EqPreset.values.length - 1)
                              const Divider(
                                height: 1,
                                color: Color(0x334FDBCC),
                              ),
                          ],
                        );
                      })
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (preset != null && context.mounted) {
      await _setEqualizerPreset(context, preset);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const RetroHeader(),
    body: ListenableBuilder(
      listenable: Listenable.merge([
        controller,
        libraryController,
        settingsController,
      ]),
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          _LocalLibrarySummary(controller: libraryController),
          const SizedBox(height: 22),
          const SectionLabel('Music Library', color: AppColors.cyan),
          const SizedBox(height: 10),
          RetroPanel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const _InfoRow(
                  icon: Icons.folder_open,
                  title: 'Scan Scope',
                  subtitle:
                      'Music and Download/Music • audio ≥30 sec • ≥300 KB',
                ),
                const Divider(height: 1, color: Color(0x334FDBCC)),
                _ActionRow(
                  icon: Icons.sync,
                  title: 'Rescan Library',
                  subtitle: 'Find newly added, moved or removed tracks.',
                  actionLabel: libraryController.status == LibraryStatus.loading
                      ? 'SCANNING'
                      : 'SCAN',
                  onTap: libraryController.status == LibraryStatus.loading
                      ? null
                      : libraryController.refresh,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionLabel('Audio Controls'),
          const SizedBox(height: 10),
          RetroPanel(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Master Volume', style: _titleStyle),
                    const Spacer(),
                    Text(
                      '${(controller.state.volume * 100).round()}%',
                      style: const TextStyle(color: AppColors.amber),
                    ),
                  ],
                ),
                Slider(value: controller.state.volume, onChanged: _setVolume),
                const Text(
                  'Saved locally and restored the next time the deck starts.',
                  style: _subtitleStyle,
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0x334FDBCC)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Equalizer Preset', style: _titleStyle),
                          SizedBox(height: 3),
                          Text(
                            'Native Android DSP applied to the player output.',
                            style: _subtitleStyle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: Platform.isAndroid
                          ? () => _chooseEqualizerPreset(context)
                          : null,
                      icon: const Icon(Icons.tune, size: 17),
                      label: Text(
                        settingsController.equalizerPreset.toUpperCase(),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionLabel(
            'System Status • Read Only',
            color: AppColors.cyan,
          ),
          const SizedBox(height: 10),
          RetroPanel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Row(
                    children: [
                      Text(
                        'SIGNAL MONITOR',
                        style: TextStyle(
                          color: AppColors.outline,
                          fontSize: 8,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.lock_outline,
                        size: 12,
                        color: AppColors.outline,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'STATUS ONLY',
                        style: TextStyle(color: AppColors.outline, fontSize: 8),
                      ),
                    ],
                  ),
                ),
                const _StatusRow(
                  icon: Icons.headphones,
                  title: 'Headphone Disconnect',
                  subtitle:
                      'Playback pauses automatically when audio output disconnects.',
                  status: 'ACTIVE',
                  active: true,
                ),
                const Divider(height: 1, color: Color(0x334FDBCC)),
                const _StatusRow(
                  icon: Icons.notifications_active_outlined,
                  title: 'Background Playback',
                  subtitle:
                      'Media notification and lock-screen controls are enabled.',
                  status: 'ACTIVE',
                  active: true,
                ),
                const Divider(height: 1, color: Color(0x334FDBCC)),
                _StatusRow(
                  icon: Icons.equalizer,
                  title: 'Equalizer / DSP',
                  subtitle: Platform.isAndroid
                      ? 'Native frequency-band processing is available.'
                      : 'A native iOS audio unit is not implemented yet.',
                  status: Platform.isAndroid ? 'ACTIVE' : 'PLANNED',
                  active: Platform.isAndroid,
                ),
              ],
            ),
          ),
          if (settingsController.errorMessage != null) ...[
            const SizedBox(height: 14),
            Text(
              'SETTINGS SAVE ERROR: ${settingsController.errorMessage}',
              style: const TextStyle(color: AppColors.error, fontSize: 10),
            ),
          ],
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'LOCAL DECK • NO ACCOUNT • NO CLOUD SYNC',
              style: TextStyle(
                color: AppColors.outline,
                fontSize: 8,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

enum _EqPreset {
  flat('Flat', 'Uncolored output signal.', [2, 2, 2, 2, 2]),
  warm('Warm', 'Soft highs with fuller low mids.', [4, 4, 3, 2, 1]),
  bass('Bass', 'Extra weight in the low frequencies.', [5, 4, 2, 2, 2]),
  vocal('Vocal', 'Clearer speech and lead vocals.', [1, 2, 5, 4, 2]),
  bright('Bright', 'More detail and high-frequency air.', [1, 2, 3, 4, 5]);

  const _EqPreset(this.label, this.description, this.curve);
  final String label;
  final String description;
  final List<int> curve;
}

class _EqCurve extends StatelessWidget {
  const _EqCurve({required this.values});
  final List<int> values;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 42,
    height: 30,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: values
          .map(
            (value) => Container(
              width: 5,
              height: 5.0 + value * 4,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                color: value >= 4 ? AppColors.amber : AppColors.cyan,
                borderRadius: BorderRadius.circular(1),
                boxShadow: [
                  BoxShadow(
                    color: (value >= 4 ? AppColors.amber : AppColors.cyan)
                        .withValues(alpha: .25),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    ),
  );
}

class _LocalLibrarySummary extends StatelessWidget {
  const _LocalLibrarySummary({required this.controller});

  final LibraryController controller;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (controller.status) {
      LibraryStatus.loading => ('● SCANNING', AppColors.amber),
      LibraryStatus.ready => ('● READY', AppColors.cyan),
      LibraryStatus.empty => ('○ EMPTY', AppColors.outline),
      LibraryStatus.permissionDenied => ('○ LOCKED', AppColors.error),
      LibraryStatus.error => ('● ERROR', AppColors.error),
    };
    return RetroPanel(
      color: const Color(0xFF232B2B),
      child: Row(
        children: [
          const Icon(
            Icons.sd_storage_outlined,
            color: AppColors.cyan,
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LOCAL MUSIC LIBRARY', style: _titleStyle),
                const SizedBox(height: 3),
                Text(
                  '${controller.tracks.length} tracks indexed',
                  style: _subtitleStyle,
                ),
              ],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
    leading: Icon(icon, color: AppColors.cyan),
    title: Text(title, style: _titleStyle),
    subtitle: Text(subtitle, style: _subtitleStyle),
    trailing: TextButton(onPressed: onTap, child: Text(actionLabel)),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
    leading: Icon(icon, color: AppColors.cyan),
    title: Text(title, style: _titleStyle),
    subtitle: Text(subtitle, style: _subtitleStyle),
  );
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.active,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final signalColor = active ? AppColors.cyan : AppColors.outlineDark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: signalColor),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _titleStyle),
                const SizedBox(height: 3),
                Text(subtitle, style: _subtitleStyle),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: signalColor,
                  shape: BoxShape.circle,
                  boxShadow: active
                      ? [BoxShadow(color: signalColor, blurRadius: 7)]
                      : null,
                ),
              ),
              const SizedBox(height: 5),
              Text(status, style: TextStyle(color: signalColor, fontSize: 8)),
            ],
          ),
        ],
      ),
    );
  }
}

const _titleStyle = TextStyle(
  fontFamily: 'sans-serif',
  fontWeight: FontWeight.w700,
  fontSize: 15,
);

const _subtitleStyle = TextStyle(
  fontFamily: 'sans-serif',
  color: AppColors.textWarm,
  fontSize: 11,
);
