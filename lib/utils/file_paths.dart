import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resolves the per-user app-data folder that holds the SQLite database
/// and copies of attached proof PDFs. Using app-data (rather than referencing
/// files in place) means the app keeps working if the user later moves or
/// deletes the original file they picked.
class AppPaths {
  static Directory? _appDir;

  static Future<Directory> appDataDirectory() async {
    if (_appDir != null) return _appDir!;
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'BayTracker'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _appDir = dir;
    return dir;
  }

  static Future<String> databasePath() async {
    final dir = await appDataDirectory();
    return p.join(dir.path, 'baytracker.db');
  }

  static Future<Directory> proofsDirectoryForTruck(int truckId) async {
    final dir = await appDataDirectory();
    final truckDir = Directory(p.join(dir.path, 'proofs', truckId.toString()));
    if (!await truckDir.exists()) {
      await truckDir.create(recursive: true);
    }
    return truckDir;
  }
}
