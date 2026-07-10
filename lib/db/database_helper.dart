import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../utils/file_paths.dart';
import 'schema.dart';

/// Singleton wrapper around the app's single SQLite database file.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _db;
  Future<Database>? _opening;
  String? _pathOverride;

  Future<Database> get database async {
    if (_db != null) return _db!;
    // Guard against concurrent first-callers (multiple controllers read
    // `database` during app startup) racing to open/configure the DB twice.
    _opening ??= _open();
    _db = await _opening;
    return _db!;
  }

  /// Test-only: point the singleton at a fresh database file and force a
  /// reopen. Lets repository tests run against a real (temp-file) SQLite
  /// database instead of the app's actual data file.
  Future<void> resetForTesting(String path) async {
    await closeForTesting();
    _pathOverride = path;
  }

  Future<void> closeForTesting() async {
    if (_db != null) {
      await _db!.close();
    }
    _db = null;
    _opening = null;
    _pathOverride = null;
  }

  Future<Database> _open() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final path = _pathOverride ?? await AppPaths.databasePath();

    return databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          for (final statement in createStatements) {
            await db.execute(statement);
          }
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            for (final statement in migrateV1ToV2) {
              await db.execute(statement);
            }
          }
        },
      ),
    );
  }
}
