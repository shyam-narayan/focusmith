import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../logging/app_logger.dart';
import '../logging/console_logger.dart';

/// Service to handle local key-value storage using Hive.
///
/// Used specifically for window states, workspace layout settings,
/// and application preferences.
class HiveStorageService {
  final AppLogger _logger;

  /// Default constructor requiring a logger dependency.
  HiveStorageService(this._logger);

  // Box Names
  static const String settingsBox = 'settings';
  static const String windowStateBox = 'window_state';
  static const String workspaceStateBox = 'workspace_state';

  /// Initializes the Hive storage and pre-opens standard boxes.
  Future<void> init() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final hivePath = p.join(directory.path, 'hive');

      final dir = Directory(hivePath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      Hive.init(hivePath);
      
      // Open boxes synchronously during app startup to permit synchronous reads later
      await Future.wait([
        Hive.openBox(settingsBox),
        Hive.openBox(windowStateBox),
        Hive.openBox(workspaceStateBox),
      ]);
      
      _logger.info('HiveStorageService initialized successfully at $hivePath.');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize HiveStorageService', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Read a value from a box.
  T? get<T>(String boxName, String key, {T? defaultValue}) {
    try {
      final box = Hive.box(boxName);
      return box.get(key, defaultValue: defaultValue) as T?;
    } catch (e) {
      _logger.warning('Failed to read key "$key" from box "$boxName". Returning default.', error: e);
      return defaultValue;
    }
  }

  /// Write a value to a box.
  Future<void> put<T>(String boxName, String key, T value) async {
    try {
      final box = Hive.box(boxName);
      await box.put(key, value);
    } catch (e, stackTrace) {
      _logger.error('Failed to write key "$key" to box "$boxName".', error: e, stackTrace: stackTrace);
    }
  }

  /// Delete a key from a box.
  Future<void> delete(String boxName, String key) async {
    try {
      final box = Hive.box(boxName);
      await box.delete(key);
    } catch (e, stackTrace) {
      _logger.error('Failed to delete key "$key" from box "$boxName".', error: e, stackTrace: stackTrace);
    }
  }

  /// Clear all entries from a box.
  Future<void> clear(String boxName) async {
    try {
      final box = Hive.box(boxName);
      await box.clear();
    } catch (e, stackTrace) {
      _logger.error('Failed to clear box "$boxName".', error: e, stackTrace: stackTrace);
    }
  }
}

/// Provider exposing [HiveStorageService].
final hiveStorageServiceProvider = Provider<HiveStorageService>((ref) {
  final logger = ref.watch(loggerProvider);
  return HiveStorageService(logger);
});
