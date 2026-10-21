import '../entities/player.dart';

abstract class PlayerRepository {
  Future<List<Player>> getPlayers({bool includeDeleted = false, String? search, String? sortBy});
  Future<Player?> getPlayerById(int id);
  Future<Player?> getPlayerByName(String name);
  Future<int> insertPlayer(Player player);
  Future<int> updatePlayer(Player player);
  Future<int> softDeletePlayer(int id);
  Future<int> restorePlayer(int id);
  Future<void> updateLastPlayed(List<int> playerIds, DateTime timestamp);
  Future<int> countActivePlayers();
}
