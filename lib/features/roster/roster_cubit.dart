import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/player.dart';
import '../../domain/repositories/player_repository.dart';

abstract class RosterState extends Equatable {
  const RosterState();
  @override
  List<Object?> get props => [];
}

class RosterInitial extends RosterState {}

class RosterLoading extends RosterState {}

class RosterLoaded extends RosterState {
  final List<Player> players;
  final String searchQuery;
  final String sortBy; // 'custom', 'name', or 'last_played'

  const RosterLoaded({
    required this.players,
    this.searchQuery = '',
    this.sortBy = 'custom',
  });

  @override
  List<Object?> get props => [players, searchQuery, sortBy];
}

class RosterError extends RosterState {
  final String message;
  const RosterError(this.message);

  @override
  List<Object?> get props => [message];
}

class RosterCubit extends Cubit<RosterState> {
  final PlayerRepository _playerRepository;
  String _currentQuery = '';
  String _currentSort = 'custom';

  RosterCubit(this._playerRepository) : super(RosterInitial());

  Future<void> loadPlayers() async {
    emit(RosterLoading());
    try {
      final players = await _playerRepository.getPlayers(
        includeDeleted: false,
        search: _currentQuery,
        sortBy: _currentSort,
      );
      emit(RosterLoaded(
        players: players,
        searchQuery: _currentQuery,
        sortBy: _currentSort,
      ));
    } catch (e) {
      emit(RosterError('Failed to load players: $e'));
    }
  }

  void search(String query) async {
    _currentQuery = query;
    try {
      final players = await _playerRepository.getPlayers(
        includeDeleted: false,
        search: _currentQuery,
        sortBy: _currentSort,
      );
      emit(RosterLoaded(
        players: players,
        searchQuery: _currentQuery,
        sortBy: _currentSort,
      ));
    } catch (e) {
      emit(RosterError('Search error: $e'));
    }
  }

  void toggleSort() async {
    if (_currentSort == 'custom') {
      _currentSort = 'name';
    } else if (_currentSort == 'name') {
      _currentSort = 'last_played';
    } else {
      _currentSort = 'custom';
    }
    await loadPlayers();
  }

  Future<bool> addPlayer({
    required String name,
    String? nickname,
    required int color,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return false;

    final existing = await _playerRepository.getPlayerByName(trimmedName);
    if (existing != null && !existing.isDeleted) {
      return false; // duplicate name
    }

    final trimmedNickname = (nickname == null || nickname.trim().isEmpty) ? null : nickname.trim();

    if (existing != null && existing.isDeleted) {
      // Re-activate soft-deleted player with updated properties and append to bottom
      final allPlayers = await _playerRepository.getPlayers(includeDeleted: true);
      final nextOrder = allPlayers.isEmpty
          ? 1
          : (allPlayers.map((p) => p.sortOrder).fold<int>(0, (max, v) => v > max ? v : max) + 1);

      await _playerRepository.updatePlayer(existing.copyWith(
        nickname: trimmedNickname,
        color: color,
        isDeleted: false,
        sortOrder: nextOrder,
      ));
    } else {
      final newPlayer = Player(
        name: trimmedName,
        nickname: trimmedNickname,
        color: color,
        createdAt: DateTime.now(),
      );
      await _playerRepository.insertPlayer(newPlayer);
    }

    await loadPlayers();
    return true;
  }

  Future<bool> editPlayer(Player updated) async {
    final existing = await _playerRepository.getPlayerByName(updated.name.trim());
    if (existing != null && existing.id != updated.id && !existing.isDeleted) {
      return false; // another player has this name
    }

    await _playerRepository.updatePlayer(updated);
    await loadPlayers();
    return true;
  }

  Future<void> deletePlayer(int id) async {
    await _playerRepository.softDeletePlayer(id);
    await loadPlayers();
  }

  Future<void> deleteAllPlayers() async {
    await _playerRepository.softDeleteAllPlayers();
    await loadPlayers();
  }

  Future<void> restorePlayer(int id) async {
    await _playerRepository.restorePlayer(id);
    await loadPlayers();
  }

  Future<void> reorderPlayers(int oldIndex, int newIndex) async {
    if (state is! RosterLoaded) return;
    final currentState = state as RosterLoaded;
    if (currentState.sortBy != 'custom') return;

    final items = List<Player>.from(currentState.players);
    final movedItem = items.removeAt(oldIndex);
    items.insert(newIndex, movedItem);

    // Optimistically emit updated state
    emit(RosterLoaded(
      players: items,
      searchQuery: currentState.searchQuery,
      sortBy: currentState.sortBy,
    ));

    // Persist new order
    final playerIds = items.map((p) => p.id!).toList();
    await _playerRepository.reorderPlayers(playerIds);
  }
}
