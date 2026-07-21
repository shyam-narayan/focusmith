import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Horizontal rule embed for story documents.
class DividerBlockEmbed extends BlockEmbed {
  const DividerBlockEmbed() : super(dividerType, 'hr');

  static const String dividerType = 'divider';
}

class DividerEmbedBuilder extends EmbedBuilder {
  const DividerEmbedBuilder();

  @override
  String get key => DividerBlockEmbed.dividerType;

  @override
  String toPlainText(Embed node) =>
      '\n────────────────────────────────────────\n';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    const lineColor = Color(0xE6FFFFFF);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Container(height: 1, color: lineColor),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: lineColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Container(height: 1, color: lineColor),
          ),
        ],
      ),
    );
  }
}

/// Inserts a document separator at the current caret, with surrounding newlines.
void insertDocumentSeparator(QuillController controller) {
  final index = controller.selection.baseOffset;
  final length = controller.selection.extentOffset - index;
  controller.replaceText(
    index,
    length < 0 ? 0 : length,
    const DividerBlockEmbed(),
    null,
  );
  controller.replaceText(
    index + 1,
    0,
    '\n',
    TextSelection.collapsed(offset: index + 2),
  );
}

/// Returns true when [node] sits inside a Quill code block.
///
/// Block-level `code-block` lives on the parent [Block], not on [Line.style].
bool _isInCodeBlock(QuillText node) {
  final line = node.parent;
  if (line == null) return false;

  final parent = line.parent;
  if (parent is Block) {
    return parent.style.containsKey(Attribute.codeBlock.key);
  }

  return line.style.containsKey(Attribute.codeBlock.key);
}

/// Span builder that keeps code-block lines visually uniform.
///
/// Inline color/font/link attrs (often from paste) can override mono styling
/// and make symbols look like normal body text — this ignores those overrides.
InlineSpan focusmithSpanBuilder(
  BuildContext context,
  Node node,
  int nodeOffset,
  String text,
  TextStyle? style,
  GestureRecognizer? recognizer,
) {
  if (node is QuillText) {
    if (_isInCodeBlock(node)) {
      final codeStyle = QuillStyles.getStyles(context, false)?.code?.style;
      if (codeStyle != null) {
        return TextSpan(text: text, style: codeStyle);
      }
    }
  }
  return defaultSpanBuilder(
    context,
    node,
    nodeOffset,
    text,
    style,
    recognizer,
  );
}

/// Smart code toggle:
/// - Non-empty selection within a single line → inline code
/// - Collapsed caret or multi-line selection → code block
void toggleSmartCode(QuillController controller) {
  final attrs = controller.getSelectionStyle().attributes;
  final hasInline = attrs.containsKey(Attribute.inlineCode.key);
  final hasBlock = attrs.containsKey(Attribute.codeBlock.key);

  if (hasInline) {
    controller.formatSelection(Attribute.clone(Attribute.inlineCode, null));
    return;
  }
  if (hasBlock) {
    controller.formatSelection(Attribute.clone(Attribute.codeBlock, null));
    return;
  }

  final selection = controller.selection;
  final plain = controller.document.toPlainText();
  final start = selection.start.clamp(0, plain.length);
  final end = selection.end.clamp(0, plain.length);

  final useInline =
      !selection.isCollapsed && !_spansMultipleLines(plain, start, end);

  if (useInline) {
    _clearInlineFormatsInSelection(controller);
    controller.formatSelection(Attribute.inlineCode);
  } else {
    _clearInlineFormatsInSelection(controller);
    controller.formatSelection(Attribute.codeBlock);
  }
}

void _clearInlineFormatsInSelection(QuillController controller) {
  for (final attr in <Attribute<dynamic>>[
    Attribute.bold,
    Attribute.italic,
    Attribute.underline,
    Attribute.strikeThrough,
    Attribute.inlineCode,
    Attribute.link,
    Attribute.color,
    Attribute.background,
  ]) {
    controller.formatSelection(Attribute.clone(attr, null));
  }
}

bool _spansMultipleLines(String plain, int start, int end) {
  if (end <= start) return false;
  return plain.substring(start, end).contains('\n');
}

bool isSmartCodeActive(QuillController controller) {
  final attrs = controller.getSelectionStyle().attributes;
  return attrs.containsKey(Attribute.inlineCode.key) ||
      attrs.containsKey(Attribute.codeBlock.key);
}
