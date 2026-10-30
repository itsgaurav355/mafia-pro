import 'package:flutter_test/flutter_test.dart';
import 'package:mafia_pro/domain/entities/player.dart';
import 'package:mafia_pro/domain/repositories/player_repository.dart';
import 'package:mafia_pro/features/roster/roster_cubit.dart';

class MockPlayerRepository implements PlayerRepository {
  List<Player> _players = [];

  MockPlayerRepository([List<Player>? initial]) {
    _players = initial ?? [];
  }

  @override
  Future<List<Player>> getPlayers({bool includeDeleted = false, String? search, String? sortBy}) async {
    var result = _players.where((p) => includeDeleted || !p.isDeleted).toList();
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      result = result.where((p) =>
        p.name.toLowerCase().contains(q) || (p.nickname != null && p.nickname!.toLowerCase().contains(q))
      ).toList();
    }
    if (sortBy == 'name') {
      result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (sortBy == 'last_played') {
      result.sort((a, b) {
        if (a.lastPlayedAt == null && b.lastPlayedAt == null) return 0;
        if (a.lastPlayedAt == null) return 1;
        if (b.lastPlayedAt == null) return -1;
        return b.lastPlayedAt!.compareTo(a.lastPlayedAt!);
      });
    } else {
      result.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    return result;
  }

  @override
  Future<Player?> getPlayerById(int id) async {
    try {
      return _players.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Player?> getPlayerByName(String name) async {
    try {
      return _players.firstWhere((p) => p.name.toLowerCase() == name.trim().toLowerCase());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> insertPlayer(Player player) async {
    final nextId = _players.isEmpty ? 1 : (_players.map((p) => p.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);
    final nextSort = _players.isEmpty ? 1 : (_players.map((p) => p.sortOrder).reduce((a, b) => a > b ? a : b) + 1);
    final p = player.copyWith(id: nextId, sortOrder: player.sortOrder == 0 ? nextSort : player.sortOrder);
    _players.add(p);
    return nextId;
  }

  @override
  Future<int> updatePlayer(Player player) async {
    final idx = _players.indexWhere((p) => p.id == player.id);
    if (idx != -1) {
      _players[idx] = player;
      return 1;
    }
    return 0;
  }

  @override
  Future<int> softDeletePlayer(int id) async {
    final idx = _players.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _players[idx] = _players[idx].copyWith(isDeleted: true);
      return 1;
    }
    return 0;
  }

  @override
  Future<void> softDeleteAllPlayers() async {
    _players = _players.map((p) => p.copyWith(isDeleted: true)).toList();
  }

  @override
  Future<int> restorePlayer(int id) async {
    final idx = _players.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _players[idx] = _players[idx].copyWith(isDeleted: false);
      return 1;
    }
    return 0;
  }

  @override
  Future<void> updateLastPlayed(List<int> playerIds, DateTime timestamp) async {}

  @override
  Future<int> countActivePlayers() async => _players.where((p) => !p.isDeleted).length;

  @override
  Future<void> reorderPlayers(List<int> playerIds) async {
    for (int i = 0; i < playerIds.length; i++) {
      final idx = _players.indexWhere((p) => p.id == playerIds[i]);
      if (idx != -1) {
        _players[idx] = _players[idx].copyWith(sortOrder: i + 1);
      }
    }
  }
}

void main() {
  group('Player Entity copyWith tests', () {
    test('Clearing nickname by passing null sets nickname to null', () {
      final player = Player(
        id: 1,
        name: 'Michael',
        nickname: 'Don Corleone',
        color: 0xFF000000,
        createdAt: DateTime.now(),
      );
      expect(player.nickname, equals('Don Corleone'));

      // Copy with null nickname must clear it
      final cleared = player.copyWith(nickname: null);
      expect(cleared.nickname, isNull);
      expect(cleared.displayName, equals('Michael'));

      // Copy without passing nickname preserves it
      final unchanged = player.copyWith(name: 'Michael Jr');
      expect(unchanged.name, equals('Michael Jr'));
      expect(unchanged.nickname, equals('Don Corleone'));
    });
  });

  group('RosterCubit Management Tests', () {
    late MockPlayerRepository repo;
    late RosterCubit cubit;

    setUp(() {
      repo = MockPlayerRepository([
        Player(id: 1, name: 'Vito', nickname: 'The Godfather', color: 0xFF111111, createdAt: DateTime.now(), sortOrder: 1),
        Player(id: 2, name: 'Sonny', nickname: 'Santino', color: 0xFF222222, createdAt: DateTime.now(), sortOrder: 2),
        Player(id: 3, name: 'Michael', nickname: 'Don', color: 0xFF333333, createdAt: DateTime.now(), sortOrder: 3),
      ]);
      cubit = RosterCubit(repo);
    });

    test('Loads players in custom order by default', () async {
      await cubit.loadPlayers();
      expect(cubit.state, isA<RosterLoaded>());
      final state = cubit.state as RosterLoaded;
      expect(state.sortBy, equals('custom'));
      expect(state.players.length, equals(3));
      expect(state.players[0].name, equals('Vito'));
      expect(state.players[1].name, equals('Sonny'));
      expect(state.players[2].name, equals('Michael'));
    });

    test('Edit player can remove nickname', () async {
      await cubit.loadPlayers();
      final original = (cubit.state as RosterLoaded).players.first;
      expect(original.nickname, equals('The Godfather'));

      // Remove nickname
      final updated = original.copyWith(nickname: null);
      final ok = await cubit.editPlayer(updated);
      expect(ok, isTrue);

      final state = cubit.state as RosterLoaded;
      expect(state.players.first.nickname, isNull);
      expect(state.players.first.displayName, equals('Vito'));
    });

    test('deleteAllPlayers clears all active players from roster', () async {
      await cubit.loadPlayers();
      expect((cubit.state as RosterLoaded).players.length, equals(3));

      await cubit.deleteAllPlayers();
      final state = cubit.state as RosterLoaded;
      expect(state.players, isEmpty);
    });

    test('Adding players after initial keeps them in order of addition and allows reordering', () async {
      await cubit.loadPlayers();

      // Add 4th player
      await cubit.addPlayer(name: 'Tom Hagen', color: 0xFF444444);
      // Add 5th player
      await cubit.addPlayer(name: 'Fredo', color: 0xFF555555);

      var state = cubit.state as RosterLoaded;
      expect(state.players.length, equals(5));
      expect(state.players[3].name, equals('Tom Hagen'));
      expect(state.players[4].name, equals('Fredo'));

      // Reorder Fredo (index 4) to index 0
      await cubit.reorderPlayers(4, 0);

      state = cubit.state as RosterLoaded;
      expect(state.players[0].name, equals('Fredo'));
      expect(state.players[1].name, equals('Vito'));
      expect(state.players[2].name, equals('Sonny'));
      expect(state.players[3].name, equals('Michael'));
      expect(state.players[4].name, equals('Tom Hagen'));
    });
  });
}

