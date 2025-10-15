import 'dart:io';
import 'package:the_book_tool/index.dart';
import 'package:path/path.dart' as path;

class DatabaseManager {
  static const String _keyCurrentDatabase = 'current_database';
  static const String _defaultDatabaseName = 'book_tool.db';

  Future<String> getCurrentDatabaseName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCurrentDatabase) ?? _defaultDatabaseName;
  }

  Future<void> setCurrentDatabase(String databaseName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentDatabase, databaseName);
  }

  Future<String> getCurrentDatabasePath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final databaseName = await getCurrentDatabaseName();
    return path.join(documentsDirectory.path, databaseName);
  }

  Future<List<String>> listDatabaseFiles() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final directory = Directory(documentsDirectory.path);

    if (!await directory.exists()) {
      return [];
    }

    final files = await directory
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.db'))
        .map((entity) => path.basename(entity.path))
        .toList();

    return files;
  }

  Future<bool> databaseExists(String databaseName) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = path.join(documentsDirectory.path, databaseName);
    final file = File(dbPath);
    return await file.exists();
  }

  Future<String> createNewDatabase(String databaseName) async {
    // Ensure .db extension
    if (!databaseName.endsWith('.db')) {
      databaseName = '$databaseName.db';
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = path.join(documentsDirectory.path, databaseName);

    // Check if file already exists
    final file = File(dbPath);
    if (await file.exists()) {
      throw Exception('Database "$databaseName" already exists');
    }

    return databaseName;
  }

  Future<void> switchDatabase(String databaseName) async {
    // Close current database
    await DatabaseService.close();

    // Set new current database
    await setCurrentDatabase(databaseName);

    // Initialize new database
    await DatabaseService.initialize();
  }

  Future<void> deleteDatabase(String databaseName) async {
    final currentDb = await getCurrentDatabaseName();

    // Prevent deleting the current database
    if (databaseName == currentDb) {
      throw Exception(
        'Cannot delete the current database. Switch to another database first.',
      );
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = path.join(documentsDirectory.path, databaseName);
    final file = File(dbPath);

    if (!await file.exists()) {
      throw Exception('Database "$databaseName" does not exist');
    }

    await file.delete();
  }
}
