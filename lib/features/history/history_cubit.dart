import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/game.dart';
import '../../domain/repositories/game_repository.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();
  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<Game> games;
  const HistoryLoaded(this.games);

  @override
  List<Object?> get props => [games];
}

class HistoryError extends HistoryState {
  final String message;
  const HistoryError(this.message);

  @override
  List<Object?> get props => [message];
}

class HistoryCubit extends Cubit<HistoryState> {
  final GameRepository _gameRepository;

  HistoryCubit(this._gameRepository) : super(HistoryInitial());

  Future<void> loadHistory() async {
    emit(HistoryLoading());
    try {
      final games = await _gameRepository.getFinishedGames();
      emit(HistoryLoaded(games));
    } catch (e) {
      emit(HistoryError('Failed to load history: $e'));
    }
  }
}
