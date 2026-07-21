import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../workspace/domain/story.dart';
import '../../workspace/presentation/providers/workspace_provider.dart';

class PriorityBoard extends ConsumerWidget {
  const PriorityBoard({super.key, this.onStorySelected});

  /// Called after a board item is selected (used to keep rearrange-mode focus).
  final ValueChanged<String>? onStorySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceProvider);
    final notifier = ref.read(workspaceProvider.notifier);

    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'PRIORITY BOARD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Tooltip(
                  message: workspace.isPriorityReorderMode
                      ? 'Exit rearrange mode'
                      : 'Rearrange priorities (Alt+Shift+↑/↓)',
                  child: IconButton(
                    icon: Icon(
                      FluentIcons.sort_lines,
                      size: 16,
                      color: workspace.isPriorityReorderMode
                          ? AppColors.accentLight
                          : AppColors.textSecondary,
                    ),
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        workspace.isPriorityReorderMode
                            ? AppColors.accent.withValues(alpha: 0.22)
                            : Colors.transparent,
                      ),
                    ),
                    onPressed: notifier.togglePriorityReorderMode,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    FluentIcons.add,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => notifier.createStory(),
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: workspace.stories.length,
              onReorder: notifier.reorderStories,
              buildDefaultDragHandles: false,
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final t = Curves.easeOut.transform(animation.value);
                    return material.Material(
                      elevation: 2 + 6 * t,
                      color: Colors.transparent,
                      shadowColor: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                      clipBehavior: Clip.antiAlias,
                      child: child,
                    );
                  },
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final story = workspace.stories[index];
                return _PriorityItem(
                  key: ValueKey(story.id),
                  index: index,
                  story: story,
                  isActive: story.id == workspace.selectedStoryId,
                  onTap: () {
                    notifier.selectStory(story.id);
                    onStorySelected?.call(story.id);
                  },
                  onMoveUp: () => notifier.moveStory(story.id, -1),
                  onMoveDown: () => notifier.moveStory(story.id, 1),
                  onRename: (title) => notifier.renameStory(story.id, title),
                  onDelete: () => notifier.deleteStory(story.id),
                );
              },
            ),
          ),
          if (workspace.isPriorityReorderMode)
            const _PriorityShortcutsLegend(),
          _ZoomControl(zoom: workspace.zoom, onChanged: notifier.setZoom),
        ],
      ),
    );
  }
}

class _PriorityItem extends StatefulWidget {
  const _PriorityItem({
    super.key,
    required this.index,
    required this.story,
    required this.isActive,
    required this.onTap,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRename,
    required this.onDelete,
  });

  final int index;
  final Story story;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final Future<void> Function(String title) onRename;
  final VoidCallback onDelete;

  @override
  State<_PriorityItem> createState() => _PriorityItemState();
}

class _PriorityItemState extends State<_PriorityItem> {
  final _flyoutController = FlyoutController();
  final _titleController = TextEditingController();
  final _titleFocusNode = FocusNode();
  bool _isEditing = false;
  bool _isCommitting = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.story.title;
    _titleFocusNode.addListener(_handleTitleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _PriorityItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.story.title != widget.story.title) {
      _titleController.text = widget.story.title;
    }
  }

  @override
  void dispose() {
    _titleFocusNode
      ..removeListener(_handleTitleFocusChanged)
      ..dispose();
    _titleController.dispose();
    _flyoutController.dispose();
    super.dispose();
  }

  void _handleTitleFocusChanged() {
    if (_isEditing && !_titleFocusNode.hasFocus) {
      _commitRename();
    }
  }

  void _startEditing() {
    if (_isEditing) return;
    setState(() {
      _isEditing = true;
      _titleController
        ..text = widget.story.title
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.story.title.length,
        );
    });
    // Select the story without interrupting the rename session.
    widget.onTap();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isEditing) {
        _titleFocusNode.requestFocus();
      }
    });
  }

  Future<void> _commitRename() async {
    if (_isCommitting) return;
    _isCommitting = true;
    final title = _titleController.text.trim();
    if (title.isNotEmpty && title != widget.story.title) {
      await widget.onRename(title);
    } else {
      _titleController.text = widget.story.title;
    }
    if (mounted) {
      setState(() => _isEditing = false);
    }
    _isCommitting = false;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        clipBehavior: Clip.hardEdge,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: widget.isActive
              ? AppColors.surfaceElevated
              : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.isActive ? AppColors.borderActive : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: widget.index,
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(
                  FluentIcons.grid_view_small,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isEditing ? null : widget.onTap,
              child: Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '${widget.index + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _isEditing
                  ? TextBox(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      autofocus: true,
                      maxLines: 1,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      onSubmitted: (_) => _commitRename(),
                    )
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onTap,
                      onDoubleTap: _startEditing,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          widget.story.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: widget.isActive
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: widget.isActive
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isEditing ? null : widget.onTap,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.fromInt(widget.story.color),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 4),
            FlyoutTarget(
              controller: _flyoutController,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  widget.onTap();
                  _flyoutController.showFlyout<void>(
                    placementMode: FlyoutPlacementMode.bottomRight,
                    builder: (context) => MenuFlyout(
                      items: [
                        MenuFlyoutItem(
                          leading: const Icon(FluentIcons.up, size: 14),
                          text: const Text('Move up'),
                          onPressed: widget.onMoveUp,
                        ),
                        MenuFlyoutItem(
                          leading: const Icon(FluentIcons.down, size: 14),
                          text: const Text('Move down'),
                          onPressed: widget.onMoveDown,
                        ),
                        const MenuFlyoutSeparator(),
                        MenuFlyoutItem(
                          leading: const Icon(FluentIcons.delete, size: 14),
                          text: const Text('Delete'),
                          onPressed: widget.onDelete,
                        ),
                      ],
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    FluentIcons.more_vertical,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityShortcutsLegend extends StatelessWidget {
  const _PriorityShortcutsLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Move Priority',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          SizedBox(height: 8),
          _ShortcutRow(label: 'Shift + Alt + ↑', caption: 'Move Up'),
          SizedBox(height: 4),
          _ShortcutRow(label: 'Shift + Alt + ↓', caption: 'Move Down'),
        ],
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({required this.label, required this.caption});

  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          caption,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _ZoomControl extends StatelessWidget {
  const _ZoomControl({required this.zoom, required this.onChanged});

  final double zoom;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              FluentIcons.remove,
              size: 14,
              color: AppColors.textMuted,
            ),
            onPressed: () => onChanged(zoom - 0.05),
          ),
          Expanded(
            child: Slider(
              value: zoom,
              min: 0.75,
              max: 1.5,
              onChanged: onChanged,
            ),
          ),
          Text(
            '${(zoom * 100).round()}%',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          IconButton(
            icon: const Icon(
              FluentIcons.add,
              size: 14,
              color: AppColors.textMuted,
            ),
            onPressed: () => onChanged(zoom + 0.05),
          ),
        ],
      ),
    );
  }
}
