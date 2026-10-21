import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/game_constants.dart';
import '../../domain/entities/game_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../database/database_service.dart';

class SqliteSettingsRepository implements SettingsRepository {
  static const String _settingsKey = 'game_default_settings';

  @override
  Future<GameSettings> getSettings() async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [_settingsKey],
      limit: 1,
    );

    if (maps.isEmpty) {
      return const GameSettings();
    }

    final value = maps.first['value'] as String;
    return GameSettings.fromJson(value);
  }

  @override
  Future<void> saveSettings(GameSettings settings) async {
    final db = await DatabaseService.database;
    await db.insert(
      'app_settings',
      {'key': _settingsKey, 'value': settings.toJson()},
      conflictAlgorithm: null, // replace handled below
    ).catchError((_) async {
      return await db.update(
        'app_settings',
        {'value': settings.toJson()},
        where: 'key = ?',
        whereArgs: [_settingsKey],
      );
    });
  }

  @override
  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(GameConstants.keyHasSeenOnboarding) ?? false;
  }

  @override
  Future<void> setHasSeenOnboarding(bool seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(GameConstants.keyHasSeenOnboarding, seen);
  }

  @override
  Future<String> exportDatabaseJson() async {
    final db = await DatabaseService.database;
    final players = await db.query('players');
    final games = await db.query('games');
    final gamePlayers = await db.query('game_players');
    final gameEvents = await db.query('game_events');
    final settings = await db.query('app_settings');

    final exportData = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'players': players,
      'games': games,
      'game_players': gamePlayers,
      'game_events': gameEvents,
      'app_settings': settings,
    };

    return jsonEncode(exportData);
  }

  @override
  Future<bool> importDatabaseJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final db = await DatabaseService.database;

      await db.transaction((txn) async {
        if (data.containsKey('players')) {
          final players = (data['players'] as List).cast<Map<String, dynamic>>();
          for (final p in players) {
            await txn.insert('players', p, conflictAlgorithm: null).catchError((_) => 0);
          }
        }
        if (data.containsKey('games')) {
          final games = (data['games'] as List).cast<Map<String, dynamic>>();
          for (final g in games) {
            await txn.insert('games', g, conflictAlgorithm: null).catchError((_) => 0);
          }
        }
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
