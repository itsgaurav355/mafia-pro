import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafia_pro/data/database/database_service.dart';
import 'package:mafia_pro/data/repositories/sqlite_game_repository.dart';
import 'package:mafia_pro/data/repositories/sqlite_player_repository.dart';
import 'package:mafia_pro/data/repositories/sqlite_role_repository.dart';
import 'package:mafia_pro/domain/engine/role_distributor.dart';
import 'package:mafia_pro/domain/entities/game.dart';
import 'package:mafia_pro/domain/entities/game_settings.dart';
import 'package:mafia_pro/domain/entities/player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => '.',
  );

  setUp(() async {
    // Ensure test environment uses sqflite ffi
    final db = await DatabaseService.database;
    // Clear tables
    await db.delete('game_events');
    await db.delete('game_players');
    await db.delete('games');
  });

  test('Deal roles flow with standard players', () async {
    final gameRepo = SqliteGameRepository();
    final playerRepo = SqlitePlayerRepository();
    final roleRepo = SqliteRoleRepository();

    final players = await playerRepo.getPlayers(includeDeleted: false);
    final roles = await roleRepo.getAllRoles();
    expect(players.length, greaterThanOrEqualTo(5));
    expect(roles.length, greaterThanOrEqualTo(5));

    final selectedPlayers = players.take(6).toList();
    final roleCounts = {
      'don': 1,
      'mafia': 1,
      'commissioner': 1,
      'doctor': 1,
      'civilian': 2,
    };

    final newGame = Game(
      startedAt: DateTime.now(),
      status: GameStatus.reveal,
      currentRound: 1,
      currentPhase: GamePhase.night,
      settings: GameSettings(roleCounts: roleCounts),
    );
    final gameId = await gameRepo.createGame(newGame);
    expect(gameId, greaterThan(0));

    final rolesMap = {for (final r in roles) r.key: r};
    final gamePlayers = RoleDistributor.distributeRoles(
      gameId: gameId,
      players: selectedPlayers,
      roleCounts: roleCounts,
      availableRolesMap: rolesMap,
    );

    await gameRepo.insertGamePlayers(gamePlayers);

    final realPlayerIds = selectedPlayers
        .where((p) => p.id != null && p.id! > 0)
        .map((p) => p.id!)
        .toList();
    await playerRepo.updateLastPlayed(realPlayerIds, DateTime.now());

    final saved = await gameRepo.getGamePlayers(gameId);
    expect(saved.length, equals(6));
  });

  test('Deal roles flow with Guest Player', () async {
    final gameRepo = SqliteGameRepository();
    final playerRepo = SqlitePlayerRepository();
    final roleRepo = SqliteRoleRepository();

    final players = await playerRepo.getPlayers(includeDeleted: false);
    final roles = await roleRepo.getAllRoles();

    final selectedPlayers = players.take(4).toList();
    final guest = Player(
      id: -101,
      name: 'Sherlock (Guest)',
      color: 0xFF123456,
      createdAt: DateTime.now(),
    );
    final allParticipants = [...selectedPlayers, guest];

    final roleCounts = {
      'don': 1,
      'mafia': 1,
      'commissioner': 1,
      'doctor': 1,
      'civilian': 1,
    };

    final newGame = Game(
      startedAt: DateTime.now(),
      status: GameStatus.reveal,
      currentRound: 1,
      currentPhase: GamePhase.night,
      settings: GameSettings(roleCounts: roleCounts),
    );
    final gameId = await gameRepo.createGame(newGame);

    final resolvedParticipants = <Player>[];
    for (final p in allParticipants) {
      if (p.id != null && p.id! > 0) {
        resolvedParticipants.add(p);
      } else {
        var dbPlayer = await playerRepo.getPlayerByName(p.name);
        if (dbPlayer == null) {
          final guestId = await playerRepo.insertPlayer(Player(
            name: p.name,
            color: p.color,
            isDeleted: true,
            createdAt: DateTime.now(),
          ));
          dbPlayer = p.copyWith(id: guestId);
        }
        resolvedParticipants.add(dbPlayer);
      }
    }

    final rolesMap = {for (final r in roles) r.key: r};
    final gamePlayers = RoleDistributor.distributeRoles(
      gameId: gameId,
      players: resolvedParticipants,
      roleCounts: roleCounts,
      availableRolesMap: rolesMap,
    );

    await gameRepo.insertGamePlayers(gamePlayers);

    final saved = await gameRepo.getGamePlayers(gameId);
    expect(saved.length, equals(5));

    // Also verify that the active roster still has only the original 8 players and does NOT show Sherlock (Guest)
    final rosterPlayers = await playerRepo.getPlayers(includeDeleted: false);
    expect(rosterPlayers.any((p) => p.name == 'Sherlock (Guest)'), isFalse);
  });

  test('Deal roles flow with repeated guest in subsequent game', () async {
    final gameRepo = SqliteGameRepository();
    final playerRepo = SqlitePlayerRepository();
    final roleRepo = SqliteRoleRepository();

    final players = await playerRepo.getPlayers(includeDeleted: false);
    final roles = await roleRepo.getAllRoles();

    final guest = Player(
      id: -100,
      name: 'Gaurav (Guest)',
      color: 0xFF654321,
      createdAt: DateTime.now(),
    );
    final allParticipants = [...players.take(4), guest];

    final roleCounts = {
      'don': 1,
      'mafia': 1,
      'commissioner': 1,
      'doctor': 1,
      'civilian': 1,
    };

    for (int gameNum = 1; gameNum <= 2; gameNum++) {
      final newGame = Game(
        startedAt: DateTime.now(),
        status: GameStatus.reveal,
        currentRound: 1,
        currentPhase: GamePhase.night,
        settings: GameSettings(roleCounts: roleCounts),
      );
      final gameId = await gameRepo.createGame(newGame);

      final resolvedParticipants = <Player>[];
      for (final p in allParticipants) {
        if (p.id != null && p.id! > 0) {
          resolvedParticipants.add(p);
        } else {
          var dbPlayer = await playerRepo.getPlayerByName(p.name);
          if (dbPlayer == null) {
            try {
              final guestId = await playerRepo.insertPlayer(Player(
                name: p.name,
                color: p.color,
                isDeleted: true,
                createdAt: DateTime.now(),
              ));
              dbPlayer = p.copyWith(id: guestId);
            } catch (_) {
              dbPlayer = await playerRepo.getPlayerByName(p.name);
            }
          }
          resolvedParticipants.add(dbPlayer ?? p);
        }
      }

      final rolesMap = {for (final r in roles) r.key: r};
      final gamePlayers = RoleDistributor.distributeRoles(
        gameId: gameId,
        players: resolvedParticipants,
        roleCounts: roleCounts,
        availableRolesMap: rolesMap,
      );

      await gameRepo.insertGamePlayers(gamePlayers);
      final saved = await gameRepo.getGamePlayers(gameId);
      expect(saved.length, equals(5));
      expect(saved.any((gp) => gp.displayNameSnapshot.startsWith('Gaurav (Guest)')), isTrue);
    }
  });
}
