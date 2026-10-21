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
  final String sortBy; // 'name' or 'last_played'

  const RosterLoaded({
    required this.players,
    this.searchQuery = '',
    this.sortBy = 'name',
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
  String _currentSort = 'name';

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
    _currentSort = _currentSort == 'name' ? 'last_played' : 'name';
    await loadPlayers();
  }

  Future<bool> addPlayer({
    required String name,
    String? nickname,
    required int color,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return false;

    // Check unique name case-insensitive (PRD F1)
    final existing = await _playerRepository.getPlayerByName(trimmedName);
    if (existing != null && !existing.isDeleted) {
      return false; // duplicate name
    }

    if (existing != null && existing.isDeleted) {
      // Re-activate soft-deleted player with updated properties
      await _playerRepository.updatePlayer(existing.copyWith(
        nickname: nickname?.trim(),
        color: color,
        isDeleted: false,
      ));
    } else {
      final newPlayer = Player(
        name: trimmedName,
        nickname: nickname?.trim(),
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

  Future<void> restorePlayer(int id) async {
    await _playerRepository.restorePlayer(id);
    await loadPlayers();
  }
}
