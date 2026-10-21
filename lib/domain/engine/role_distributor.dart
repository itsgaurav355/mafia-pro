import 'dart:math';
import '../entities/game_player.dart';
import '../entities/player.dart';
import '../entities/role.dart';

class RoleDistributor {
  /// Assigns roles to players using cryptographically secure Random
  static List<GamePlayer> distributeRoles({
    required int gameId,
    required List<Player> players,
    required Map<String, int> roleCounts,
    required Map<String, Role> availableRolesMap,
  }) {
    final secureRandom = Random.secure();

    // 1. Build the role deck
    final roleDeck = <Role>[];
    roleCounts.forEach((roleKey, count) {
      final role = availableRolesMap[roleKey];
      if (role != null) {
        for (int i = 0; i < count; i++) {
          roleDeck.add(role);
        }
      }
    });

    if (roleDeck.length != players.length) {
      throw ArgumentError(
        'Role deck size (${roleDeck.length}) does not match player count (${players.length})',
      );
    }

    // 2. Fisher-Yates shuffle with Random.secure()
    for (int i = roleDeck.length - 1; i > 0; i--) {
      final n = secureRandom.nextInt(i + 1);
      final temp = roleDeck[i];
      roleDeck[i] = roleDeck[n];
      roleDeck[n] = temp;
    }

    // 3. Map to GamePlayer entities
    final gamePlayers = <GamePlayer>[];
    for (int i = 0; i < players.length; i++) {
      final player = players[i];
      final assignedRole = roleDeck[i];

      gamePlayers.add(GamePlayer(
        gameId: gameId,
        playerId: player.id ?? (i + 1),
        roleId: assignedRole.id ?? (i + 1),
        displayNameSnapshot: player.displayName,
        isAlive: true,
        roleKey: assignedRole.key,
        roleName: assignedRole.name,
        roleTeam: assignedRole.team.value,
        avatarColor: player.color,
      ));
    }

    return gamePlayers;
  }
}
