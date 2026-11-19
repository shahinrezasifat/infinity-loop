import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

import '../models/repo_model.dart';

class RepoSeeder {
  static const _dbName = 'sifats_play.db';
  static const _seededKey = 'is_seeded';

  static Future<Database> openDatabaseFile() async {
    if (Platform.isWindows || Platform.isLinux) {
      ffi.sqfliteFfiInit();
      databaseFactory = ffi.databaseFactoryFfi;
    }
    final dir = Platform.isAndroid
        ? await getApplicationDocumentsDirectory()
        : await getApplicationSupportDirectory();
    return databaseFactory.openDatabase(
      p.join(dir.path, _dbName),
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE repositories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              ecosystem TEXT NOT NULL,
              category TEXT NOT NULL,
              manifestUrl TEXT NOT NULL,
              isNsfw INTEGER NOT NULL DEFAULT 0,
              shortcode TEXT
            )
          ''');
          await db.execute(
            'CREATE TABLE app_meta (key TEXT PRIMARY KEY, value TEXT)',
          );
          await _createAutoLinkTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) await _createAutoLinkTables(db);
        },
      ),
    );
  }

  static Future<void> _createAutoLinkTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS auto_link_repositories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        ecosystem TEXT NOT NULL,
        isEnabled INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS auto_link_sources (
        id TEXT PRIMARY KEY,
        repo_id TEXT NOT NULL DEFAULT 'auto_link_repo',
        title TEXT NOT NULL,
        url TEXT NOT NULL UNIQUE,
        link_type TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (repo_id) REFERENCES auto_link_repositories(id)
          ON DELETE CASCADE
      )
    ''');
  }

  static Future<List<RepoModel>> seedIfNeeded() async {
    final db = await openDatabaseFile();
    final meta = await db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: [_seededKey],
    );
    if (meta.isEmpty) {
      final raw = await rootBundle.loadString('assets/preloaded_repos.json');
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      await db.transaction((txn) async {
        for (final map in list) {
          await txn.insert(
            'repositories',
            RepoModel.fromAsset(map).toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await txn.insert('app_meta', {'key': _seededKey, 'value': 'true'});
      });
    }
    final rows = await db.query('repositories', orderBy: 'id');
    await db.close();
    return rows.map(RepoModel.fromMap).toList(growable: false);
  }

  static Future<void> addRepository(RepoModel repo) async {
    final db = await openDatabaseFile();
    await db.insert(
      'repositories',
      repo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.close();
  }
}
