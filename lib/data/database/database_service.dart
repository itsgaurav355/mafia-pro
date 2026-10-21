import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/roles/role_registry.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    // If running on desktop (macOS, Windows, Linux) or during tests, initialize ffi
    if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String dbPath;
    if (kIsWeb) {
      dbPath = 'mafia_pro.db';
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      dbPath = p.join(docDir.path, 'mafia_pro.db');
    }

    return await openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seedRoles(db);
        await _seedSamplePlayers(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Migration logic with PRAGMA user_version if schema changes in future
      },
    );
  }

  static Future<void> _createSchema(Database db) async {
    // 1. Players table
    await db.execute('''
      CREATE TABLE players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE COLLATE NOCASE NOT NULL,
        nickname TEXT,
        color INTEGER NOT NULL,
        is_deleted INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        last_played_at TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_players_name ON players(name)');

    // 2. Roles table
    await db.execute('''
      CREATE TABLE roles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        team TEXT NOT NULL,
        night_order INTEGER DEFAULT 0,
        has_night_action INTEGER DEFAULT 0,
        is_builtin INTEGER DEFAULT 1,
        default_enabled INTEGER DEFAULT 1,
        default_count INTEGER DEFAULT 1
      )
    ''');

    // 3. Games table
    await db.execute('''
      CREATE TABLE games (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        status TEXT NOT NULL,
        current_round INTEGER DEFAULT 1,
        current_phase TEXT DEFAULT 'night',
        winner_team TEXT,
        settings_json TEXT NOT NULL
      )
    ''');

    // 4. Game Players table
    await db.execute('''
      CREATE TABLE game_players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id INTEGER NOT NULL,
        player_id INTEGER,
        role_id INTEGER NOT NULL,
        display_name_snapshot TEXT NOT NULL,
        is_alive INTEGER DEFAULT 1,
        eliminated_round INTEGER,
        eliminated_by TEXT,
        FOREIGN KEY (game_id) REFERENCES games (id) ON DELETE CASCADE,
        FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE SET NULL,
        FOREIGN KEY (role_id) REFERENCES roles (id)
      )
    ''');
    await db.execute('CREATE INDEX idx_game_players_game_id ON game_players(game_id)');

    // 5. Game Events table
    await db.execute('''
      CREATE TABLE game_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id INTEGER NOT NULL,
        round INTEGER NOT NULL,
        phase TEXT NOT NULL,
        event_type TEXT NOT NULL,
        actor_game_player_id INTEGER,
        target_game_player_id INTEGER,
        result TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (game_id) REFERENCES games (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_game_events_game_round ON game_events(game_id, round)');

    // 6. Role Presets table
    await db.execute('''
      CREATE TABLE role_presets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        config_json TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 7. App Settings table
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _seedRoles(Database db) async {
    final batch = db.batch();
    for (final role in RoleRegistry.getAll()) {
      int defaultCount = 1;
      int defaultEnabled = 1;

      if (role.key == 'civilian') {
        defaultCount = 2;
      } else if (['detective_sidekick', 'jester', 'bodyguard', 'escort', 'maniac'].contains(role.key)) {
        defaultEnabled = 0;
        defaultCount = 0;
      }

      batch.insert('roles', {
        'key': role.key,
        'name': role.name,
        'team': role.team.value,
        'night_order': role.nightOrder,
        'has_night_action': role.hasNightAction ? 1 : 0,
        'is_builtin': 1,
        'default_enabled': defaultEnabled,
        'default_count': defaultCount,
      });
    }
    await batch.commit(noResult: true);
  }

  static Future<void> _seedSamplePlayers(Database db) async {
    final now = DateTime.now().toIso8601String();
    final samplePlayers = [
      {'name': 'Vito', 'nickname': 'The Godfather', 'color': AppColors.playerAvatarColors[0].toARGB32()},
      {'name': 'Sonny', 'nickname': 'Santino', 'color': AppColors.playerAvatarColors[1].toARGB32()},
      {'name': 'Michael', 'nickname': 'Don Corleone', 'color': AppColors.playerAvatarColors[2].toARGB32()},
      {'name': 'Tom Hagen', 'nickname': 'Consigliere', 'color': AppColors.playerAvatarColors[3].toARGB32()},
      {'name': 'Luca Brasi', 'nickname': 'Enforcer', 'color': AppColors.playerAvatarColors[4].toARGB32()},
      {'name': 'Clemenza', 'nickname': 'Caporegime', 'color': AppColors.playerAvatarColors[5].toARGB32()},
      {'name': 'Fredo', 'nickname': 'Underdog', 'color': AppColors.playerAvatarColors[6].toARGB32()},
      {'name': 'Kay Adams', 'nickname': 'Outsider', 'color': AppColors.playerAvatarColors[7].toARGB32()},
    ];

    final batch = db.batch();
    for (final p in samplePlayers) {
      batch.insert('players', {
        'name': p['name'],
        'nickname': p['nickname'],
        'color': p['color'],
        'is_deleted': 0,
        'created_at': now,
        'last_played_at': null,
      });
    }
    await batch.commit(noResult: true);
  }
}
