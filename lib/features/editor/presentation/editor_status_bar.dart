import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/settings/app_settings.dart';
import '../../workspace/presentation/providers/workspace_provider.dart';

class EditorStatusBar extends ConsumerWidget {
  const EditorStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceProvider);
    // documentEpoch ensures counts refresh while typing.
    final _ = workspace.documentEpoch;
    final notifier = ref.read(workspaceProvider.notifier);
    final words = notifier.wordCountForActive();
    final chars = notifier.charCountForActive();
    final autosave = ref.watch(appSettingsProvider).autosaveEnabled;

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text(
            'Words: $words',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(width: 16),
          Text(
            'Characters: $chars',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const Spacer(),
          _SaveIndicator(
            status: workspace.saveStatus,
            lastSavedAt: workspace.lastSavedAt,
          ),
          const Spacer(),
          Text(
            autosave ? 'Autosave on · Ctrl+S' : 'Ctrl + S to save',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveIndicator extends StatelessWidget {
  const _SaveIndicator({required this.status, required this.lastSavedAt});

  final SaveStatus status;
  final DateTime? lastSavedAt;

  @override
  Widget build(BuildContext context) {
    final (icon, text, color) = switch (status) {
      SaveStatus.saved => (
        FluentIcons.completed_solid,
        _savedLabel(lastSavedAt),
        AppColors.success,
      ),
      SaveStatus.saving => (FluentIcons.sync, 'Saving...', AppColors.warning),
      SaveStatus.unsaved => (
        FluentIcons.edit,
        'Unsaved changes',
        AppColors.warning,
      ),
      SaveStatus.error => (
        FluentIcons.error,
        'Save failed',
        const Color(0xFFEF4444),
      ),
    };

    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }

  String _savedLabel(DateTime? time) {
    if (time == null) return 'Saved';
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Saved just now';
    return 'Saved ${DateFormat.jm().format(time)}';
  }
}
