import 'package:sqflite/sqflite.dart';
import '../../domain/entities/player.dart';
import '../../domain/repositories/player_repository.dart';
import '../database/database_service.dart';

class SqlitePlayerRepository implements PlayerRepository {
  @override
  Future<List<Player>> getPlayers({
    bool includeDeleted = false,
    String? search,
    String? sortBy, // 'name' or 'last_played'
  }) async {
    final db = await DatabaseService.database;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (!includeDeleted) {
      whereClauses.add('is_deleted = 0');
    }

    if (search != null && search.trim().isNotEmpty) {
      whereClauses.add('(name LIKE ? OR nickname LIKE ?)');
      whereArgs.add('%${search.trim()}%');
      whereArgs.add('%${search.trim()}%');
    }

    String orderBy = 'name COLLATE NOCASE ASC';
    if (sortBy == 'last_played') {
      orderBy = 'last_played_at DESC, name COLLATE NOCASE ASC';
    }

    final maps = await db.query(
      'players',
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderBy,
    );

    return maps.map((m) => Player.fromMap(m)).toList();
  }

  @override
  Future<Player?> getPlayerById(int id) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'players',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Player.fromMap(maps.first);
  }

  @override
  Future<Player?> getPlayerByName(String name) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'players',
      where: 'name = ? COLLATE NOCASE',
      whereArgs: [name.trim()],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Player.fromMap(maps.first);
  }

  @override
  Future<int> insertPlayer(Player player) async {
    final db = await DatabaseService.database;
    return await db.insert('players', player.toMap());
  }

  @override
  Future<int> updatePlayer(Player player) async {
    final db = await DatabaseService.database;
    return await db.update(
      'players',
      player.toMap(),
      where: 'id = ?',
      whereArgs: [player.id],
    );
  }

  @override
  Future<int> softDeletePlayer(int id) async {
    final db = await DatabaseService.database;
    return await db.update(
      'players',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> restorePlayer(int id) async {
    final db = await DatabaseService.database;
    return await db.update(
      'players',
      {'is_deleted': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateLastPlayed(List<int> playerIds, DateTime timestamp) async {
    final db = await DatabaseService.database;
    final batch = db.batch();
    for (final id in playerIds) {
      batch.update(
        'players',
        {'last_played_at': timestamp.toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<int> countActivePlayers() async {
    final db = await DatabaseService.database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM players WHERE is_deleted = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
