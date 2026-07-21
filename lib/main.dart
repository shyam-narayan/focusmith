import 'dart:async';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as acrylic;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'core/constants/app_fonts.dart';
import 'core/database/hive_storage_service.dart';
import 'core/database/sqlite_service.dart';
import 'core/logging/console_logger.dart';
import 'core/theme/app_theme.dart';
import 'features/workspace/data/note_repository_impl.dart';
import 'features/workspace/data/seed_data_service.dart';
import 'features/workspace/data/story_repository_impl.dart';
import 'features/workspace/presentation/providers/workspace_provider.dart';
import 'features/workspace/presentation/workspace_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  final logger = container.read(loggerProvider);

  logger.info('Initializing FOCUSMITH startup services...');

  try {
    await windowManager.ensureInitialized();
    if (Platform.isWindows) {
      await acrylic.Window.initialize();
    }

    await container.read(hiveStorageServiceProvider).init();
    await container.read(sqliteServiceProvider).init();

    await SeedDataService(
      storyRepository: container.read(storyRepositoryProvider),
      noteRepository: container.read(noteRepositoryProvider),
      sqliteService: container.read(sqliteServiceProvider),
    ).seedIfEmpty();

    final hiveService = container.read(hiveStorageServiceProvider);
    final width = hiveService.get<double>(HiveStorageService.windowStateBox, 'width') ?? 1440.0;
    final height = hiveService.get<double>(HiveStorageService.windowStateBox, 'height') ?? 900.0;
    final x = hiveService.get<double>(HiveStorageService.windowStateBox, 'x');
    final y = hiveService.get<double>(HiveStorageService.windowStateBox, 'y');

    const windowOptions = WindowOptions(
      size: Size(1440, 900),
      minimumSize: Size(1100, 720),
      center: true,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
      title: 'FOCUSMITH',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setSize(Size(width, height));
      if (x != null && y != null) {
        await windowManager.setPosition(Offset(x, y));
      }
      await windowManager.show();
      await windowManager.focus();

      if (Platform.isWindows) {
        await acrylic.Window.setEffect(
          effect: acrylic.WindowEffect.mica,
          color: const Color(0xCC0B0B0F),
        );
      }
    });

    logger.info('FOCUSMITH startup completed successfully. Launching app UI...');

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const FocusmithApp(),
      ),
    );
  } catch (e, stackTrace) {
    logger.error('Fatal crash during app bootstrap.', error: e, stackTrace: stackTrace);
    rethrow;
  }
}

class FocusmithApp extends ConsumerWidget {
  const FocusmithApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FluentApp(
      title: 'FOCUSMITH',
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: FlutterQuillLocalizations.supportedLocales,
      builder: (context, child) {
        return DefaultTextStyle.merge(
          style: const TextStyle(fontFamily: AppFonts.family),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const WindowStateObserver(
        child: WorkspaceShell(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WindowStateObserver extends StatefulWidget {
  const WindowStateObserver({super.key, required this.child});

  final Widget child;

  @override
  State<WindowStateObserver> createState() => _WindowStateObserverState();
}

class _WindowStateObserverState extends State<WindowStateObserver>
    with WindowListener {
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    unawaited(windowManager.setPreventClose(true));
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void onWindowClose() async {
    if (_isClosing) return;
    _isClosing = true;
    try {
      final container = ProviderScope.containerOf(context);
      await container.read(workspaceProvider.notifier).prepareForAppExit();
    } catch (_) {
      // Still close — better to exit than trap the user.
    }
    await windowManager.destroy();
  }

  @override
  void onWindowResized() async {
    final container = ProviderScope.containerOf(context);
    final size = await windowManager.getSize();
    final hive = container.read(hiveStorageServiceProvider);
    await hive.put(HiveStorageService.windowStateBox, 'width', size.width);
    await hive.put(HiveStorageService.windowStateBox, 'height', size.height);
  }

  @override
  void onWindowMoved() async {
    final container = ProviderScope.containerOf(context);
    final pos = await windowManager.getPosition();
    final hive = container.read(hiveStorageServiceProvider);
    await hive.put(HiveStorageService.windowStateBox, 'x', pos.dx);
    await hive.put(HiveStorageService.windowStateBox, 'y', pos.dy);
  }
}
