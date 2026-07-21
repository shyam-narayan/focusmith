import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../workspace/presentation/providers/workspace_provider.dart';
import 'editor_embeds.dart';
import 'editor_find_bar.dart';
import 'story_editor_toolbar.dart';

class StoryEditorPanel extends ConsumerStatefulWidget {
  const StoryEditorPanel({super.key});

  @override
  ConsumerState<StoryEditorPanel> createState() => _StoryEditorPanelState();
}

class _StoryEditorPanelState extends ConsumerState<StoryEditorPanel> {
  final _titleController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _editorKey = GlobalKey<EditorState>();
  String? _boundStoryId;

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _syncTitleField(String? storyId, String title) {
    if (_boundStoryId == storyId && _titleFocusNode.hasFocus) return;
    if (_boundStoryId != storyId || _titleController.text != title) {
      _boundStoryId = storyId;
      _titleController.value = TextEditingValue(
        text: title,
        selection: TextSelection.collapsed(offset: title.length),
      );
    }
  }

  Future<void> _commitTitle() async {
    final storyId = _boundStoryId;
    if (storyId == null) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      final current = ref.read(workspaceProvider).selectedStory?.title ?? '';
      _titleController.text = current;
      return;
    }
    await ref.read(workspaceProvider.notifier).renameStory(storyId, title);
  }

  material.ThemeData get _materialTheme => material.ThemeData.dark().copyWith(
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.surface,
    cardColor: AppColors.surfaceElevated,
    dividerColor: AppColors.border,
    splashFactory: material.InkRipple.splashFactory,
    iconTheme: const material.IconThemeData(
      color: AppColors.textSecondary,
      size: 18,
    ),
    textTheme: material.ThemeData.dark().textTheme.apply(
      fontFamily: AppFonts.family,
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    primaryTextTheme: material.ThemeData.dark().primaryTextTheme.apply(
      fontFamily: AppFonts.family,
    ),
    textSelectionTheme: material.TextSelectionThemeData(
      cursorColor: AppColors.accentLight,
      selectionColor: AppColors.accent.withValues(alpha: 0.35),
      selectionHandleColor: AppColors.accent,
    ),
    colorScheme: const material.ColorScheme.dark(
      primary: AppColors.accent,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(workspaceProvider);
    final notifier = ref.read(workspaceProvider.notifier);
    final story = workspace.selectedStory;
    final storyId = workspace.selectedStoryId;
    final controller = notifier.controllerFor(storyId);
    final focusNode = notifier.focusNodeFor(storyId);
    final scrollController = notifier.scrollControllerFor(storyId);
    final zoom = workspace.zoom;

    ref.listen<String?>(
      workspaceProvider.select((s) => s.selectedStoryId),
      (previous, next) {
        if (previous == null || previous == next) return;
        if (_boundStoryId != previous) return;
        final title = _titleController.text.trim();
        if (title.isEmpty) return;
        unawaited(notifier.renameStory(previous, title));
      },
    );

    if (workspace.isLoading) {
      return const Center(child: ProgressRing());
    }

    if (story == null ||
        controller == null ||
        focusNode == null ||
        scrollController == null) {
      return const Center(
        child: Text(
          'Select or create a story to begin.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    _syncTitleField(story.id, story.title);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyB, control: true): () =>
            controller.formatSelection(Attribute.bold),
        const SingleActivator(LogicalKeyboardKey.keyI, control: true): () =>
            controller.formatSelection(Attribute.italic),
        const SingleActivator(LogicalKeyboardKey.keyU, control: true): () =>
            controller.formatSelection(Attribute.underline),
        const SingleActivator(LogicalKeyboardKey.keyE, control: true): () =>
            toggleSmartCode(controller),
        const SingleActivator(
          LogicalKeyboardKey.digit1,
          control: true,
          alt: true,
        ): () =>
            controller.formatSelection(Attribute.h1),
        const SingleActivator(
          LogicalKeyboardKey.digit2,
          control: true,
          alt: true,
        ): () =>
            controller.formatSelection(Attribute.h2),
        const SingleActivator(
          LogicalKeyboardKey.digit3,
          control: true,
          alt: true,
        ): () =>
            controller.formatSelection(Attribute.h3),
        const SingleActivator(
          LogicalKeyboardKey.digit0,
          control: true,
          alt: true,
        ): () =>
            controller.formatSelection(Attribute.header),
      },
      child: Focus(
        autofocus: false,
        child: Column(
          children: [
            StoryEditorToolbar(controller: controller, theme: _materialTheme),
            const EditorFindBar(),
            Expanded(
              child: material.Theme(
                data: _materialTheme,
                child: material.Material(
                  color: AppColors.background,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      if (!_titleFocusNode.hasFocus) {
                        focusNode.requestFocus();
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(48, 32, 48, 0),
                          child: Focus(
                            onKeyEvent: (node, event) {
                              if (event is! KeyDownEvent) {
                                return KeyEventResult.ignored;
                              }
                              if (event.logicalKey ==
                                  LogicalKeyboardKey.enter) {
                                focusNode.requestFocus();
                                return KeyEventResult.handled;
                              }
                              return KeyEventResult.ignored;
                            },
                            child: TextBox(
                              controller: _titleController,
                              focusNode: _titleFocusNode,
                              placeholder: 'Story title',
                              style: TextStyle(
                                fontFamily: AppFonts.family,
                                fontSize: 30 * zoom,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                height: 1.25,
                                letterSpacing: -0.3,
                              ),
                              placeholderStyle: TextStyle(
                                fontFamily: AppFonts.family,
                                fontSize: 30 * zoom,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                              ),
                              decoration: null,
                              padding: EdgeInsets.zero,
                              unfocusedColor: Colors.transparent,
                              cursorColor: AppColors.accentLight,
                              onSubmitted: (_) async {
                                await _commitTitle();
                                focusNode.requestFocus();
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(48, 16, 48, 8),
                          child: Container(height: 1, color: AppColors.border),
                        ),
                        Expanded(
                          child: QuillEditor(
                            controller: controller,
                            focusNode: focusNode,
                            scrollController: scrollController,
                            config: QuillEditorConfig(
                              editorKey: _editorKey,
                              placeholder: 'Start writing…',
                              padding: const EdgeInsets.fromLTRB(
                                48,
                                12,
                                48,
                                48,
                              ),
                              autoFocus: false,
                              expands: true,
                              scrollable: true,
                              showCursor: true,
                              paintCursorAboveText: true,
                              enableInteractiveSelection: true,
                              enableSelectionToolbar: true,
                              embedBuilders: const [DividerEmbedBuilder()],
                              customLeadingBlockBuilder: _buildListLeading,
                              textSpanBuilder: focusmithSpanBuilder,
                              customShortcuts: const {
                                SingleActivator(
                                  LogicalKeyboardKey.keyZ,
                                  control: true,
                                ): UndoTextIntent(SelectionChangedCause.keyboard),
                                SingleActivator(
                                  LogicalKeyboardKey.keyZ,
                                  control: true,
                                  shift: true,
                                ): RedoTextIntent(SelectionChangedCause.keyboard),
                              },
                              onTapUp: (details, _) =>
                                  _placeCaretAtEndIfTappedBelowContent(
                                    details,
                                    controller,
                                    focusNode,
                                  ),
                              scrollPhysics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              textSelectionThemeData:
                                  material.TextSelectionThemeData(
                                    cursorColor: AppColors.accentLight,
                                    selectionColor: AppColors.accent.withValues(
                                      alpha: 0.35,
                                    ),
                                    selectionHandleColor: AppColors.accent,
                                  ),
                              customStyles: _editorStyles(zoom),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _titleFocusNode.addListener(_handleTitleFocus);
  }

  void _handleTitleFocus() {
    if (!_titleFocusNode.hasFocus) {
      _commitTitle();
    }
  }

  /// Clicks in empty space below the last line jump to end-of-document,
  /// instead of Quill mapping the X position onto the last line.
  bool _placeCaretAtEndIfTappedBelowContent(
    TapUpDetails details,
    QuillController controller,
    FocusNode focusNode,
  ) {
    final editorState = _editorKey.currentState;
    if (editorState == null) return false;

    final renderEditor = editorState.renderEditor;
    final lastChild = renderEditor.lastChild;
    if (lastChild == null) return false;

    final local = renderEditor.globalToLocal(details.globalPosition);
    final parentData = lastChild.parentData;
    if (parentData is! BoxParentData) return false;

    final contentBottom = parentData.offset.dy + lastChild.size.height;
    if (local.dy <= contentBottom) return false;

    final endOffset = (controller.document.length - 1).clamp(0, 1 << 30);
    controller.updateSelection(
      TextSelection.collapsed(offset: endOffset),
      ChangeSource.local,
    );
    focusNode.requestFocus();
    return true;
  }

  /// Tight leading width so "1." sits close to the list text.
  static double _listNumberWidth(double fontSize, int count) {
    final digits = '$count'.length;
    return fontSize * (0.55 * digits + 1.05);
  }

  static HorizontalSpacing _listIndentWidth(
    Block block,
    BuildContext context,
    int count,
    LeadingBlockNumberPointWidth numberPointWidthBuilder,
  ) {
    final defaultStyles = QuillStyles.getStyles(context, false)!;
    final fontSize = defaultStyles.paragraph?.style.fontSize ?? 16;
    final attrs = block.style.attributes;

    var extraIndent = 0.0;
    final indent = attrs[Attribute.indent.key];
    if (indent?.value != null) {
      extraIndent = fontSize * (indent!.value as num).toDouble();
    }

    if (attrs.containsKey(Attribute.blockQuote.key)) {
      return HorizontalSpacing(fontSize + extraIndent, 0);
    }

    final listAttr = attrs[Attribute.list.key];
    if (listAttr == Attribute.ol) {
      return HorizontalSpacing(
        numberPointWidthBuilder(fontSize, count) + extraIndent,
        0,
      );
    }
    if (listAttr == Attribute.ul) {
      // Bullet column just wide enough for "•" + a small gap.
      return HorizontalSpacing(fontSize * 1.15 + extraIndent, 0);
    }

    return TextBlockUtils.defaultIndentWidthBuilder(
      block,
      context,
      count,
      numberPointWidthBuilder,
    );
  }

  Widget? _buildListLeading(Node node, LeadingConfig config) {
    const gapAfterMarker = 4.0;
    if (config.attribute == Attribute.ol) {
      return _TightNumberPoint(
        index: config.getIndexNumberByIndent ?? '${(config.index ?? 0) + 1}',
        style: config.style ?? const TextStyle(),
        width: config.width ?? 24,
        gap: gapAfterMarker,
      );
    }
    if (config.attribute == Attribute.ul) {
      return _TightBulletPoint(
        style: config.style ?? const TextStyle(),
        width: config.width ?? 20,
        gap: gapAfterMarker,
      );
    }
    return null;
  }

  DefaultStyles _editorStyles(double zoom) {
    return DefaultStyles(
      placeHolder: DefaultTextBlockStyle(
        TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 15 * zoom,
          color: AppColors.textMuted,
          height: 1.65,
          fontWeight: FontWeight.w400,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
      h1: DefaultTextBlockStyle(
        TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 28 * zoom,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.25,
          letterSpacing: -0.3,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(22, 10),
        const VerticalSpacing(0, 0),
        null,
      ),
      h2: DefaultTextBlockStyle(
        TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 22 * zoom,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.3,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(18, 8),
        const VerticalSpacing(0, 0),
        null,
      ),
      h3: DefaultTextBlockStyle(
        TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 18 * zoom,
          fontWeight: FontWeight.w600,
          color: AppColors.accentLight,
          height: 1.35,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(14, 6),
        const VerticalSpacing(0, 0),
        null,
      ),
      h4: DefaultTextBlockStyle(
        TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 16 * zoom,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(12, 4),
        const VerticalSpacing(0, 0),
        null,
      ),
      h5: DefaultTextBlockStyle(
        TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 15 * zoom,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(10, 4),
        const VerticalSpacing(0, 0),
        null,
      ),
      h6: DefaultTextBlockStyle(
        TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 14 * zoom,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(8, 4),
        const VerticalSpacing(0, 0),
        null,
      ),
      paragraph: DefaultTextBlockStyle(
        TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 15 * zoom,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          height: 1.65,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(4, 4),
        const VerticalSpacing(0, 0),
        null,
      ),
      lists: DefaultListBlockStyle(
        TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 15 * zoom,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          height: 1.65,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(3, 3),
        const VerticalSpacing(0, 0),
        null,
        null,
        indentWidthBuilder: _listIndentWidth,
        numberPointWidthBuilder: _listNumberWidth,
      ),
      leading: DefaultTextBlockStyle(
        TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 15 * zoom,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          height: 1.65,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
      quote: DefaultTextBlockStyle(
        TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 14.5 * zoom,
          color: AppColors.accentLight,
          height: 1.6,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w400,
        ),
        const HorizontalSpacing(14, 10),
        const VerticalSpacing(12, 12),
        const VerticalSpacing(8, 8),
        BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.08),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          border: const Border(
            left: BorderSide(color: AppColors.accent, width: 3),
          ),
        ),
      ),
      code: DefaultTextBlockStyle(
        TextStyle(
          fontSize: 13.5 * zoom,
          fontFamily: AppFonts.mono,
          fontFamilyFallback: AppFonts.monoFallback,
          color: const Color(0xFFE5E7EB),
          height: 1.55,
          fontWeight: FontWeight.w400,
        ),
        const HorizontalSpacing(14, 14),
        const VerticalSpacing(12, 12),
        const VerticalSpacing(8, 8),
        BoxDecoration(
          color: const Color(0xFF101017),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
      ),
      inlineCode: InlineCodeStyle(
        style: TextStyle(
          fontSize: 13.5 * zoom,
          fontFamily: AppFonts.mono,
          fontFamilyFallback: AppFonts.monoFallback,
          color: AppColors.accentLight,
          fontWeight: FontWeight.w500,
          backgroundColor: AppColors.surfaceElevated,
        ),
        backgroundColor: AppColors.surfaceElevated,
        radius: const Radius.circular(4),
      ),
      bold: const TextStyle(
        fontFamily: AppFonts.family,
        fontWeight: FontWeight.w700,
      ),
      italic: const TextStyle(
        fontFamily: AppFonts.family,
        fontStyle: FontStyle.italic,
      ),
      underline: const TextStyle(
        fontFamily: AppFonts.family,
        decoration: TextDecoration.underline,
      ),
      strikeThrough: const TextStyle(
        fontFamily: AppFonts.family,
        decoration: TextDecoration.lineThrough,
      ),
      link: TextStyle(
        fontFamily: AppFonts.family,
        color: AppColors.accentLight,
        decoration: TextDecoration.underline,
        decorationColor: AppColors.accentLight.withValues(alpha: 0.6),
      ),
    );
  }
}

/// Number marker with a tight gap before list text.
class _TightNumberPoint extends StatelessWidget {
  const _TightNumberPoint({
    required this.index,
    required this.style,
    required this.width,
    required this.gap,
  });

  final String index;
  final TextStyle style;
  final double width;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Padding(
          padding: EdgeInsetsDirectional.only(end: gap),
          child: Text('$index.', style: style),
        ),
      ),
    );
  }
}

/// Bullet marker with a tight gap before list text.
class _TightBulletPoint extends StatelessWidget {
  const _TightBulletPoint({
    required this.style,
    required this.width,
    required this.gap,
  });

  final TextStyle style;
  final double width;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Padding(
          padding: EdgeInsetsDirectional.only(end: gap),
          child: Text('•', style: style),
        ),
      ),
    );
  }
}
