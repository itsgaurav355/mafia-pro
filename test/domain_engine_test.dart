import 'package:flutter_test/flutter_test.dart';
import 'package:mafia_pro/domain/engine/night_resolver.dart';
import 'package:mafia_pro/domain/engine/role_distributor.dart';
import 'package:mafia_pro/domain/engine/win_condition_checker.dart';
import 'package:mafia_pro/domain/entities/game_player.dart';
import 'package:mafia_pro/domain/entities/game_settings.dart';
import 'package:mafia_pro/domain/entities/player.dart';
import 'package:mafia_pro/domain/entities/role.dart';

void main() {
  group('RoleDistributor Tests', () {
    test('Distributes roles cryptographically matching player count', () {
      final players = List.generate(
        6,
        (i) => Player(
          id: i + 1,
          name: 'Player ${i + 1}',
          color: 0xFFFFFFFF,
          createdAt: DateTime.now(),
        ),
      );

      final rolesMap = {
        'don': const Role(
          id: 1,
          key: 'don',
          name: 'Don',
          team: RoleTeam.mafia,
          nightOrder: 10,
          hasNightAction: true,
          description: '',
        ),
        'mafia': const Role(
          id: 2,
          key: 'mafia',
          name: 'Mafia',
          team: RoleTeam.mafia,
          nightOrder: 10,
          hasNightAction: true,
          description: '',
        ),
        'commissioner': const Role(
          id: 3,
          key: 'commissioner',
          name: 'Commissioner',
          team: RoleTeam.town,
          nightOrder: 30,
          hasNightAction: true,
          description: '',
        ),
        'doctor': const Role(
          id: 4,
          key: 'doctor',
          name: 'Doctor',
          team: RoleTeam.town,
          nightOrder: 20,
          hasNightAction: true,
          description: '',
        ),
        'civilian': const Role(
          id: 5,
          key: 'civilian',
          name: 'Civilian',
          team: RoleTeam.town,
          nightOrder: 0,
          hasNightAction: false,
          description: '',
        ),
      };

      final roleCounts = {
        'don': 1,
        'mafia': 1,
        'commissioner': 1,
        'doctor': 1,
        'civilian': 2,
      };

      final distributed = RoleDistributor.distributeRoles(
        gameId: 1,
        players: players,
        roleCounts: roleCounts,
        availableRolesMap: rolesMap,
      );

      expect(distributed.length, equals(6));
      expect(distributed.where((p) => p.roleKey == 'don').length, equals(1));
      expect(distributed.where((p) => p.roleKey == 'mafia').length, equals(1));
      expect(distributed.where((p) => p.roleKey == 'commissioner').length, equals(1));
      expect(distributed.where((p) => p.roleKey == 'doctor').length, equals(1));
      expect(distributed.where((p) => p.roleKey == 'civilian').length, equals(2));
    });
  });

  group('NightResolver Tests', () {
    test('Doctor saves player from Mafia kill', () {
      final players = [
        const GamePlayer(
          id: 1,
          gameId: 1,
          playerId: 1,
          roleId: 1,
          roleKey: 'don',
          roleTeam: 'mafia',
          displayNameSnapshot: 'Don Vito',
          isAlive: true,
        ),
        const GamePlayer(
          id: 2,
          gameId: 1,
          playerId: 2,
          roleId: 2,
          roleKey: 'doctor',
          roleTeam: 'town',
          displayNameSnapshot: 'Dr. John',
          isAlive: true,
        ),
        const GamePlayer(
          id: 3,
          gameId: 1,
          playerId: 3,
          roleId: 3,
          roleKey: 'civilian',
          roleTeam: 'town',
          displayNameSnapshot: 'Civilian Joe',
          isAlive: true,
        ),
      ];

      final nightActions = [
        const NightActionTarget(roleKey: 'mafia', actorGamePlayerId: 1, targetGamePlayerId: 3),
        const NightActionTarget(roleKey: 'doctor', actorGamePlayerId: 2, targetGamePlayerId: 3),
      ];

      final result = NightResolver.resolve(
        allPlayers: players,
        nightActions: nightActions,
        settings: const GameSettings(),
      );

      // Target was saved, so no one died
      expect(result.eliminatedPlayerIds, isEmpty);
      expect(result.savedPlayerIds, contains(3));
    });

    test('Mafia eliminates target if not saved', () {
      final players = [
        const GamePlayer(
          id: 1,
          gameId: 1,
          playerId: 1,
          roleId: 1,
          roleKey: 'don',
          roleTeam: 'mafia',
          displayNameSnapshot: 'Don Vito',
          isAlive: true,
        ),
        const GamePlayer(
          id: 2,
          gameId: 1,
          playerId: 2,
          roleId: 2,
          roleKey: 'civilian',
          roleTeam: 'town',
          displayNameSnapshot: 'Civilian Joe',
          isAlive: true,
        ),
      ];

      final nightActions = [
        const NightActionTarget(roleKey: 'mafia', actorGamePlayerId: 1, targetGamePlayerId: 2),
      ];

      final result = NightResolver.resolve(
        allPlayers: players,
        nightActions: nightActions,
        settings: const GameSettings(),
      );

      expect(result.eliminatedPlayerIds, contains(2));
    });

    test('Commissioner check identifies Mafia vs Innocent Don', () {
      final players = [
        const GamePlayer(
          id: 1,
          gameId: 1,
          playerId: 1,
          roleId: 1,
          roleKey: 'commissioner',
          roleTeam: 'town',
          displayNameSnapshot: 'Inspector',
          isAlive: true,
        ),
        const GamePlayer(
          id: 2,
          gameId: 1,
          playerId: 2,
          roleId: 2,
          roleKey: 'don',
          roleTeam: 'mafia',
          displayNameSnapshot: 'Don Vito',
          isAlive: true,
        ),
        const GamePlayer(
          id: 3,
          gameId: 1,
          playerId: 3,
          roleId: 3,
          roleKey: 'mafia',
          roleTeam: 'mafia',
          displayNameSnapshot: 'Mafioso',
          isAlive: true,
        ),
      ];

      // Test check on Don (appears INNOCENT)
      final resultDon = NightResolver.resolve(
        allPlayers: players,
        nightActions: [
          const NightActionTarget(roleKey: 'commissioner', actorGamePlayerId: 1, targetGamePlayerId: 2),
        ],
        settings: const GameSettings(),
      );
      expect(resultDon.commissionerResults[2], equals('INNOCENT'));

      // Test check on regular Mafia (appears MAFIA)
      final resultMafia = NightResolver.resolve(
        allPlayers: players,
        nightActions: [
          const NightActionTarget(roleKey: 'commissioner', actorGamePlayerId: 1, targetGamePlayerId: 3),
        ],
        settings: const GameSettings(),
      );
      expect(resultMafia.commissionerResults[3], equals('MAFIA'));
    });
  });

  group('WinConditionChecker Tests', () {
    test('Town wins when all Mafia are eliminated', () {
      final players = [
        const GamePlayer(
          id: 1,
          gameId: 1,
          playerId: 1,
          roleId: 1,
          roleKey: 'don',
          roleTeam: 'mafia',
          displayNameSnapshot: 'Don Vito',
          isAlive: false,
        ),
        const GamePlayer(
          id: 2,
          gameId: 1,
          playerId: 2,
          roleId: 2,
          roleKey: 'commissioner',
          roleTeam: 'town',
          displayNameSnapshot: 'Inspector',
          isAlive: true,
        ),
        const GamePlayer(
          id: 3,
          gameId: 1,
          playerId: 3,
          roleId: 3,
          roleKey: 'civilian',
          roleTeam: 'town',
          displayNameSnapshot: 'Joe',
          isAlive: true,
        ),
      ];

      final win = WinConditionChecker.check(allPlayers: players);
      expect(win, equals(WinResult.townWin));
    });

    test('Mafia wins when Mafia count equals or exceeds non-Mafia', () {
      final players = [
        const GamePlayer(
          id: 1,
          gameId: 1,
          playerId: 1,
          roleId: 1,
          roleKey: 'don',
          roleTeam: 'mafia',
          displayNameSnapshot: 'Don Vito',
          isAlive: true,
        ),
        const GamePlayer(
          id: 2,
          gameId: 1,
          playerId: 2,
          roleId: 2,
          roleKey: 'mafia',
          roleTeam: 'mafia',
          displayNameSnapshot: 'Enforcer',
          isAlive: true,
        ),
        const GamePlayer(
          id: 3,
          gameId: 1,
          playerId: 3,
          roleId: 3,
          roleKey: 'civilian',
          roleTeam: 'town',
          displayNameSnapshot: 'Joe',
          isAlive: true,
        ),
      ];

      final win = WinConditionChecker.check(allPlayers: players);
      expect(win, equals(WinResult.mafiaWin));
    });

    test('Jester wins immediately if executed by town vote', () {
      final players = [
        const GamePlayer(
          id: 1,
          gameId: 1,
          playerId: 1,
          roleId: 1,
          roleKey: 'jester',
          roleTeam: 'neutral',
          displayNameSnapshot: 'Jester',
          isAlive: false,
        ),
      ];

      final win = WinConditionChecker.check(
        allPlayers: players,
        jesterExecutedToday: true,
      );
      expect(win, equals(WinResult.jesterWin));
    });

    test('Maniac wins as solitary survivor or with 1 other player', () {
      final players = [
        const GamePlayer(
          id: 1,
          gameId: 1,
          playerId: 1,
          roleId: 1,
          roleKey: 'maniac',
          roleTeam: 'neutral',
          displayNameSnapshot: 'The Slasher',
          isAlive: true,
        ),
        const GamePlayer(
          id: 2,
          gameId: 1,
          playerId: 2,
          roleId: 2,
          roleKey: 'civilian',
          roleTeam: 'town',
          displayNameSnapshot: 'Victim',
          isAlive: true,
        ),
      ];

      final win = WinConditionChecker.check(allPlayers: players);
      expect(win, equals(WinResult.maniacWin));
    });
  });
}
