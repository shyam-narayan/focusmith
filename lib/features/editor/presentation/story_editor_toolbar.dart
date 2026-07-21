import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import 'editor_embeds.dart';

/// Jira-comment–inspired formatting toolbar: compact sections, clear hierarchy.
class StoryEditorToolbar extends StatelessWidget {
  const StoryEditorToolbar({
    super.key,
    required this.controller,
    required this.theme,
  });

  final QuillController controller;
  final material.ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: material.Theme(
        data: theme,
        child: material.Material(
          color: AppColors.surface,
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    _HistoryGroup(controller: controller),
                    const _SectionDivider(),
                    _ParagraphStyleMenu(controller: controller),
                    const _SectionDivider(),
                    _InlineFormatGroup(controller: controller),
                    const _SectionDivider(),
                    QuillToolbarColorButton(
                      controller: controller,
                      isBackground: false,
                      options: const QuillToolbarColorButtonOptions(),
                    ),
                    const _SectionDivider(),
                    _ListGroup(controller: controller),
                    const _SectionDivider(),
                    _BlockGroup(controller: controller),
                    const _SectionDivider(),
                    _ToolbarIconButton(
                      tooltip: 'Clear formatting',
                      icon: FluentIcons.clear_formatting,
                      isActive: false,
                      onPressed: () => _clearFormatting(controller),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _clearFormatting(QuillController controller) {
    final attrs = controller.getSelectionStyle().attributes.values.toList();
    for (final attr in attrs) {
      controller.formatSelection(Attribute.clone(attr, null));
    }
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: AppColors.border,
    );
  }
}

class _HistoryGroup extends StatelessWidget {
  const _HistoryGroup({required this.controller});

  final QuillController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToolbarIconButton(
          tooltip: 'Undo (Ctrl+Z)',
          icon: FluentIcons.undo,
          isActive: false,
          enabled: controller.hasUndo,
          onPressed: controller.undo,
        ),
        _ToolbarIconButton(
          tooltip: 'Redo (Ctrl+Shift+Z)',
          icon: FluentIcons.redo,
          isActive: false,
          enabled: controller.hasRedo,
          onPressed: controller.redo,
        ),
      ],
    );
  }
}

class _ParagraphStyleMenu extends StatelessWidget {
  const _ParagraphStyleMenu({required this.controller});

  final QuillController controller;

  Attribute get _current {
    return controller.getSelectionStyle().attributes[Attribute.header.key] ??
        Attribute.header;
  }

  String get _label {
    final current = _current;
    if (current == Attribute.h1) return 'Heading 1';
    if (current == Attribute.h2) return 'Heading 2';
    if (current == Attribute.h3) return 'Heading 3';
    return 'Normal text';
  }

  @override
  Widget build(BuildContext context) {
    return DropDownButton(
      title: Text(
        _label,
        style: const TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
      items: [
        MenuFlyoutItem(
          text: const Text(
            'Normal text',
            style: TextStyle(fontFamily: AppFonts.family, fontSize: 14),
          ),
          onPressed: () => controller.formatSelection(Attribute.header),
        ),
        MenuFlyoutItem(
          text: const Text(
            'Heading 1',
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed: () => controller.formatSelection(Attribute.h1),
        ),
        MenuFlyoutItem(
          text: const Text(
            'Heading 2',
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: () => controller.formatSelection(Attribute.h2),
        ),
        MenuFlyoutItem(
          text: const Text(
            'Heading 3',
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: () => controller.formatSelection(Attribute.h3),
        ),
      ],
    );
  }
}

class _InlineFormatGroup extends StatelessWidget {
  const _InlineFormatGroup({required this.controller});

  final QuillController controller;

  bool _has(Attribute attribute) {
    return controller.getSelectionStyle().attributes.containsKey(attribute.key);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToolbarIconButton(
          tooltip: 'Bold (Ctrl+B)',
          icon: FluentIcons.bold,
          isActive: _has(Attribute.bold),
          onPressed: () => controller.formatSelection(Attribute.bold),
        ),
        _ToolbarIconButton(
          tooltip: 'Italic (Ctrl+I)',
          icon: FluentIcons.italic,
          isActive: _has(Attribute.italic),
          onPressed: () => controller.formatSelection(Attribute.italic),
        ),
        _ToolbarIconButton(
          tooltip: 'Underline (Ctrl+U)',
          icon: FluentIcons.underline,
          isActive: _has(Attribute.underline),
          onPressed: () => controller.formatSelection(Attribute.underline),
        ),
        _ToolbarIconButton(
          tooltip: 'Strikethrough',
          icon: FluentIcons.strikethrough,
          isActive: _has(Attribute.strikeThrough),
          onPressed: () => controller.formatSelection(Attribute.strikeThrough),
        ),
      ],
    );
  }
}

class _ListGroup extends StatelessWidget {
  const _ListGroup({required this.controller});

  final QuillController controller;

  bool _hasList(Attribute attribute) {
    final value = controller
        .getSelectionStyle()
        .attributes[Attribute.list.key]
        ?.value;
    return value == attribute.value;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToolbarIconButton(
          tooltip: 'Bulleted list',
          icon: FluentIcons.bulleted_list,
          isActive: _hasList(Attribute.ul),
          onPressed: () {
            if (_hasList(Attribute.ul)) {
              controller.formatSelection(Attribute.clone(Attribute.list, null));
            } else {
              controller.formatSelection(Attribute.ul);
            }
          },
        ),
        _ToolbarIconButton(
          tooltip: 'Numbered list',
          icon: FluentIcons.numbered_list,
          isActive: _hasList(Attribute.ol),
          onPressed: () {
            if (_hasList(Attribute.ol)) {
              controller.formatSelection(Attribute.clone(Attribute.list, null));
            } else {
              controller.formatSelection(Attribute.ol);
            }
          },
        ),
      ],
    );
  }
}

class _BlockGroup extends StatelessWidget {
  const _BlockGroup({required this.controller});

  final QuillController controller;

  bool _has(Attribute attribute) {
    return controller.getSelectionStyle().attributes.containsKey(attribute.key);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToolbarIconButton(
          tooltip: 'Quote',
          icon: FluentIcons.right_double_quote,
          isActive: _has(Attribute.blockQuote),
          onPressed: () {
            if (_has(Attribute.blockQuote)) {
              controller.formatSelection(
                Attribute.clone(Attribute.blockQuote, null),
              );
            } else {
              controller.formatSelection(Attribute.blockQuote);
            }
          },
        ),
        _ToolbarIconButton(
          tooltip:
              'Code (Ctrl+E) — select text for inline, otherwise code block',
          icon: FluentIcons.code,
          isActive: isSmartCodeActive(controller),
          onPressed: () => toggleSmartCode(controller),
        ),
        _ToolbarIconButton(
          tooltip: 'Insert separator',
          icon: FluentIcons.separator,
          isActive: false,
          onPressed: () => insertDocumentSeparator(controller),
        ),
      ],
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.tooltip,
    required this.icon,
    required this.isActive,
    required this.onPressed,
    this.enabled = true,
  });

  final String tooltip;
  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? AppColors.textMuted.withValues(alpha: 0.35)
        : isActive
        ? AppColors.accentLight
        : AppColors.textSecondary;

    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: IconButton(
          icon: Icon(icon, size: 15, color: color),
          onPressed: enabled ? onPressed : null,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (isActive) {
                return AppColors.accent.withValues(alpha: 0.18);
              }
              if (states.contains(WidgetState.hovered) && enabled) {
                return AppColors.surfaceElevated;
              }
              return Colors.transparent;
            }),
            padding: WidgetStateProperty.all(const EdgeInsets.all(7)),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
      ),
    );
  }
}
