import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../constants/app_colors.dart';
import '../../features/settings/presentation/settings_dialog.dart';

/// Custom application title bar matching the FOCUSMITH design mock.
class AppTitleBar extends ConsumerWidget {
  const AppTitleBar({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onSearchCleared,
    required this.onSearchFocused,
  });

  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onSearchCleared;
  final VoidCallback onSearchFocused;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragToMoveArea(
      child: Container(
        height: 52,
        padding: const EdgeInsets.only(left: 16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            _BrandMark(),
            const SizedBox(width: 24),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: _GlobalSearchField(
                    controller: searchController,
                    focusNode: searchFocusNode,
                    onChanged: onSearchChanged,
                    onSubmitted: onSearchSubmitted,
                    onCleared: onSearchCleared,
                    onFocused: onSearchFocused,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                FluentIcons.settings,
                size: 18,
                color: AppColors.textSecondary,
              ),
              onPressed: () => showSettingsDialog(context),
            ),
            const SizedBox(width: 10),
            _WindowButton(
              icon: FluentIcons.chrome_minimize,
              onPressed: () => windowManager.minimize(),
            ),
            _WindowButton(
              icon: FluentIcons.full_screen,
              onPressed: () async {
                if (await windowManager.isMaximized()) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
            ),
            _WindowButton(
              icon: FluentIcons.chrome_close,
              hoverColor: const Color(0xFFE81123),
              onPressed: () => windowManager.close(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/brand/app_icon.png',
            width: 28,
            height: 28,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'FOCUSMITH',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _GlobalSearchField extends StatelessWidget {
  const _GlobalSearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onCleared,
    required this.onFocused,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onCleared;
  final VoidCallback onFocused;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (hasFocus) onFocused();
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.fromLTRB(10, 0, 8, 0),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              FluentIcons.search,
              size: 15,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextBox(
                controller: controller,
                focusNode: focusNode,
                placeholder: 'Search all stories…',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                onChanged: onChanged,
                onSubmitted: onSubmitted,
              ),
            ),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                if (controller.text.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: IconButton(
                    icon: const Icon(
                      FluentIcons.clear,
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                    onPressed: onCleared,
                  ),
                );
              },
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Ctrl+Shift+F',
                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  const _WindowButton({
    required this.icon,
    required this.onPressed,
    this.hoverColor,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color? hoverColor;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 52,
          height: 52,
          color: _hovered
              ? (widget.hoverColor ?? AppColors.surfaceElevated)
              : Colors.transparent,
          child: Icon(
            widget.icon,
            size: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
