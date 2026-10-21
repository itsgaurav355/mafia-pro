import '../entities/game.dart';
import '../entities/game_event.dart';
import '../entities/game_player.dart';

abstract class GameRepository {
  Future<int> createGame(Game game);
  Future<void> updateGame(Game game);
  Future<Game?> getGameById(int id);
  Future<Game?> getActiveGame();
  Future<List<Game>> getFinishedGames({int limit = 50});
  
  // Game Players
  Future<void> insertGamePlayers(List<GamePlayer> gamePlayers);
  Future<List<GamePlayer>> getGamePlayers(int gameId);
  Future<void> updateGamePlayer(GamePlayer gamePlayer);

  // Events & Replay
  Future<int> insertGameEvent(GameEvent event);
  Future<List<GameEvent>> getGameEvents(int gameId);
  Future<void> deleteLatestEvent(int gameId);
}
