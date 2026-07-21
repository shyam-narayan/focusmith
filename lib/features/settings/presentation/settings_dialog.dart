import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/settings/app_settings.dart';

Future<void> showSettingsDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (context) => const _SettingsDialog(),
  );
}

class _SettingsDialog extends ConsumerWidget {
  const _SettingsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return ContentDialog(
      title: const Text('Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Editor',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          ToggleSwitch(
            checked: settings.autosaveEnabled,
            content: const Text('Autosave'),
            onChanged: (value) {
              ref.read(appSettingsProvider.notifier).setAutosaveEnabled(value);
            },
          ),
          const SizedBox(height: 6),
          Text(
            settings.autosaveEnabled
                ? 'Saves the active story a couple of seconds after you stop typing. Ctrl+S still works.'
                : 'Only saves when you press Ctrl+S (or close a tab).',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            child: const Text('Export workspace (.focusmith)'),
            onPressed: () => ref.read(backupServiceProvider).exportWorkspace(),
          ),
          const SizedBox(height: 16),
          const Text(
            'FOCUSMITH stores all data locally in SQLite on your machine.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
      actions: [
        FilledButton(
          child: const Text('Close'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
