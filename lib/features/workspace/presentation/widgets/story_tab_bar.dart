import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/story.dart';
import '../providers/workspace_provider.dart';

class StoryTabBar extends ConsumerWidget {
  const StoryTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceProvider);
    final notifier = ref.read(workspaceProvider.notifier);
    final tabs = workspace.openTabs;

    return Container(
      height: 42,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              itemCount: tabs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final story = tabs[index];
                final isActive = story.id == workspace.selectedStoryId;
                return _StoryTab(
                  story: story,
                  isActive: isActive,
                  onTap: () => notifier.selectStory(story.id),
                  onClose: () => notifier.closeStory(story.id),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(FluentIcons.add, size: 16, color: AppColors.textSecondary),
            onPressed: () => notifier.createStory(),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _StoryTab extends StatelessWidget {
  const _StoryTab({
    required this.story,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  final Story story;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.surfaceElevated : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? AppColors.borderActive : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.fromInt(story.color),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              story.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClose,
              child: const Icon(FluentIcons.chrome_close, size: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
