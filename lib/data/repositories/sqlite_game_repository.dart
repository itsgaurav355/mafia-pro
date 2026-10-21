import '../../domain/entities/game.dart';
import '../../domain/entities/game_event.dart';
import '../../domain/entities/game_player.dart';
import '../../domain/repositories/game_repository.dart';
import '../database/database_service.dart';

class SqliteGameRepository implements GameRepository {
  @override
  Future<int> createGame(Game game) async {
    final db = await DatabaseService.database;
    return await db.insert('games', game.toMap());
  }

  @override
  Future<void> updateGame(Game game) async {
    final db = await DatabaseService.database;
    await db.update(
      'games',
      game.toMap(),
      where: 'id = ?',
      whereArgs: [game.id],
    );
  }

  @override
  Future<Game?> getGameById(int id) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'games',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Game.fromMap(maps.first);
  }

  @override
  Future<Game?> getActiveGame() async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'games',
      where: 'status != ? AND status != ?',
      whereArgs: ['finished', 'archived'],
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Game.fromMap(maps.first);
  }

  @override
  Future<List<Game>> getFinishedGames({int limit = 50}) async {
    final db = await DatabaseService.database;

    // Automatically archive any older unfinished games superseded by newer sessions
    final activeGame = await getActiveGame();
    if (activeGame != null && activeGame.id != null) {
      await db.rawUpdate('''
        UPDATE games 
        SET status = 'finished',
            ended_at = COALESCE(ended_at, started_at),
            winner_team = COALESCE(winner_team, 'Archived')
        WHERE (status != 'finished' AND status != 'archived') AND id != ?
      ''', [activeGame.id]);
    }

    final maps = await db.query(
      'games',
      where: 'status = ? OR status = ?',
      whereArgs: ['finished', 'archived'],
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return maps.map((m) => Game.fromMap(m)).toList();
  }

  @override
  Future<void> insertGamePlayers(List<GamePlayer> gamePlayers) async {
    final db = await DatabaseService.database;
    final batch = db.batch();
    for (final gp in gamePlayers) {
      batch.insert('game_players', gp.toMap());
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<GamePlayer>> getGamePlayers(int gameId) async {
    final db = await DatabaseService.database;
    final maps = await db.rawQuery('''
      SELECT 
        gp.id,
        gp.game_id,
        gp.player_id,
        gp.role_id,
        gp.display_name_snapshot,
        gp.is_alive,
        gp.eliminated_round,
        gp.eliminated_by,
        r.key AS role_key,
        r.name AS role_name,
        r.team AS role_team,
        p.color AS player_color
      FROM game_players gp
      LEFT JOIN roles r ON gp.role_id = r.id
      LEFT JOIN players p ON gp.player_id = p.id
      WHERE gp.game_id = ?
      ORDER BY gp.id ASC
    ''', [gameId]);

    return maps.map((m) => GamePlayer.fromMap(m)).toList();
  }

  @override
  Future<void> updateGamePlayer(GamePlayer gamePlayer) async {
    final db = await DatabaseService.database;
    await db.update(
      'game_players',
      gamePlayer.toMap(),
      where: 'id = ?',
      whereArgs: [gamePlayer.id],
    );
  }

  @override
  Future<int> insertGameEvent(GameEvent event) async {
    final db = await DatabaseService.database;
    return await db.insert('game_events', event.toMap());
  }

  @override
  Future<List<GameEvent>> getGameEvents(int gameId) async {
    final db = await DatabaseService.database;
    final maps = await db.rawQuery('''
      SELECT 
        ge.id,
        ge.game_id,
        ge.round,
        ge.phase,
        ge.event_type,
        ge.actor_game_player_id,
        ge.target_game_player_id,
        ge.result,
        ge.created_at,
        actor_p.display_name_snapshot AS actor_name,
        target_p.display_name_snapshot AS target_name,
        r.name AS actor_role_name
      FROM game_events ge
      LEFT JOIN game_players actor_p ON ge.actor_game_player_id = actor_p.id
      LEFT JOIN game_players target_p ON ge.target_game_player_id = target_p.id
      LEFT JOIN roles r ON actor_p.role_id = r.id
      WHERE ge.game_id = ?
      ORDER BY ge.id ASC
    ''', [gameId]);

    return maps.map((m) => GameEvent.fromMap(
      m,
      actorName: m['actor_name'] as String?,
      targetName: m['target_name'] as String?,
      actorRoleName: m['actor_role_name'] as String?,
    )).toList();
  }

  @override
  Future<void> deleteLatestEvent(int gameId) async {
    final db = await DatabaseService.database;
    await db.execute('''
      DELETE FROM game_events 
      WHERE id = (
        SELECT id FROM game_events 
        WHERE game_id = ? 
        ORDER BY id DESC LIMIT 1
      )
    ''', [gameId]);
  }
}
