import 'package:flutter_test/flutter_test.dart';
import 'package:mafia_pro/domain/entities/game_settings.dart';
import 'package:mafia_pro/domain/entities/player.dart';
import 'package:mafia_pro/domain/entities/role.dart';
import 'package:mafia_pro/domain/repositories/player_repository.dart';
import 'package:mafia_pro/domain/repositories/role_repository.dart';
import 'package:mafia_pro/domain/repositories/settings_repository.dart';
import 'package:mafia_pro/features/game_setup/game_setup_cubit.dart';

class FakePlayerRepo implements PlayerRepository {
  @override
  Future<List<Player>> getPlayers({bool includeDeleted = false, String? search, String? sortBy}) async {
    return List.generate(
      8,
      (i) => Player(id: i + 1, name: 'Player ${i + 1}', color: 0xFFFFFFFF, createdAt: DateTime.now()),
    );
  }
  @override Future<int> countActivePlayers() async => 8;
  @override Future<Player?> getPlayerById(int id) async => null;
  @override Future<Player?> getPlayerByName(String name) async => null;
  @override Future<int> insertPlayer(Player player) async => 9;
  @override Future<int> restorePlayer(int id) async => 1;
  @override Future<int> softDeletePlayer(int id) async => 1;
  @override Future<void> updateLastPlayed(List<int> playerIds, DateTime timestamp) async {}
  @override Future<int> updatePlayer(Player player) async => 1;
}

class FakeRoleRepo implements RoleRepository {
  @override
  Future<List<Role>> getAllRoles() async {
    return [
      const Role(id: 1, key: 'don', name: 'Don', team: RoleTeam.mafia, nightOrder: 10, hasNightAction: true, description: ''),
      const Role(id: 2, key: 'mafia', name: 'Mafia', team: RoleTeam.mafia, nightOrder: 10, hasNightAction: true, description: ''),
      const Role(id: 3, key: 'commissioner', name: 'Commissioner', team: RoleTeam.town, nightOrder: 30, hasNightAction: true, description: ''),
      const Role(id: 4, key: 'doctor', name: 'Doctor', team: RoleTeam.town, nightOrder: 20, hasNightAction: true, description: ''),
      const Role(id: 5, key: 'vigilante', name: 'Vigilante', team: RoleTeam.town, nightOrder: 40, hasNightAction: true, defaultEnabled: false, defaultCount: 0, description: ''),
      const Role(id: 6, key: 'civilian', name: 'Civilian', team: RoleTeam.town, nightOrder: 0, hasNightAction: false, description: ''),
    ];
  }
  @override Future<Role?> getRoleById(int id) async => null;
  @override Future<Role?> getRoleByKey(String key) async => null;
}

class FakeSettingsRepo implements SettingsRepository {
  @override Future<String> exportDatabaseJson() async => '{}';
  @override Future<GameSettings> getSettings() async => const GameSettings();
  @override Future<bool> hasSeenOnboarding() async => true;
  @override Future<bool> importDatabaseJson(String jsonString) async => true;
  @override Future<void> saveSettings(GameSettings settings) async {}
  @override Future<void> setHasSeenOnboarding(bool seen) async {}
}

void main() {
  group('Civilian Auto-Balance Tests', () {
    late GameSetupCubit cubit;

    setUp(() async {
      cubit = GameSetupCubit(
        playerRepository: FakePlayerRepo(),
        roleRepository: FakeRoleRepo(),
        settingsRepository: FakeSettingsRepo(),
      );
      await cubit.init();
    });

    test('Civilian automatically receives all remaining player slots', () {
      // 8 players selected initially:
      // Don: 1, Mafia: 2, Commissioner: 1, Doctor: 1 (Total special = 5)
      // Civilian should automatically be 8 - 5 = 3
      expect(cubit.state.totalSelectedCount, equals(8));
      expect(cubit.state.roleCounts['don'], equals(1));
      expect(cubit.state.roleCounts['mafia'], equals(2));
      expect(cubit.state.roleCounts['commissioner'], equals(1));
      expect(cubit.state.roleCounts['doctor'], equals(1));
      expect(cubit.state.roleCounts['civilian'], equals(3));
      expect(cubit.state.totalAssignedRolesCount, equals(8));
    });

    test('Adding a special role automatically decrements civilian count', () {
      // Enable Vigilante (count 1)
      cubit.toggleRoleEnabled('vigilante', true);

      // Now special roles = 1 (Don) + 2 (Mafia) + 1 (Comm) + 1 (Doc) + 1 (Vig) = 6
      // Civilian should automatically become 8 - 6 = 2
      expect(cubit.state.roleCounts['vigilante'], equals(1));
      expect(cubit.state.roleCounts['civilian'], equals(2));
      expect(cubit.state.totalAssignedRolesCount, equals(8));
    });

    test('Disabling a special role automatically increments civilian count', () {
      // Disable Doctor
      cubit.toggleRoleEnabled('doctor', false);

      // Special roles = 1 (Don) + 2 (Mafia) + 1 (Comm) = 4
      // Civilian should automatically become 8 - 4 = 4
      expect(cubit.state.roleCounts['doctor'], equals(0));
      expect(cubit.state.roleCounts['civilian'], equals(4));
      expect(cubit.state.totalAssignedRolesCount, equals(8));
    });

    test('Changing special role count dynamically adjusts civilian count', () {
      // Set Mafia count to 1 (decrement from 2)
      cubit.setRoleCount('mafia', 1);

      // Special roles = 1 (Don) + 1 (Mafia) + 1 (Comm) + 1 (Doc) = 4
      // Civilian should automatically become 8 - 4 = 4
      expect(cubit.state.roleCounts['civilian'], equals(4));
      expect(cubit.state.totalAssignedRolesCount, equals(8));
    });
  });
}
