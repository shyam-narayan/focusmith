import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/hive_storage_service.dart';

class AppSettings {
  const AppSettings({this.autosaveEnabled = false});

  final bool autosaveEnabled;

  AppSettings copyWith({bool? autosaveEnabled}) {
    return AppSettings(
      autosaveEnabled: autosaveEnabled ?? this.autosaveEnabled,
    );
  }
}

class AppSettingsNotifier extends Notifier<AppSettings> {
  static const _autosaveKey = 'autosave_enabled';

  @override
  AppSettings build() {
    final hive = ref.watch(hiveStorageServiceProvider);
    final enabled = hive.get<bool>(
          HiveStorageService.settingsBox,
          _autosaveKey,
          defaultValue: false,
        ) ??
        false;
    return AppSettings(autosaveEnabled: enabled);
  }

  Future<void> setAutosaveEnabled(bool enabled) async {
    state = state.copyWith(autosaveEnabled: enabled);
    await ref.read(hiveStorageServiceProvider).put(
          HiveStorageService.settingsBox,
          _autosaveKey,
          enabled,
        );
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettings>(AppSettingsNotifier.new);
