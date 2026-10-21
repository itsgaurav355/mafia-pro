import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/game.dart';
import '../../domain/entities/game_player.dart';
import '../../domain/entities/game_settings.dart';

enum RevealStep {
  handover, // Pass phone to player, tap 'Start Choosing'
  choosing, // Fingerprint hold to reveal role
  moderatorSummary, // Last page for moderator with complete cheat sheet
}

class RoleRevealState extends Equatable {
  final Game game;
  final List<GamePlayer> gamePlayers;
  final GameSettings settings;
  final int currentPlayerIndex;
  final RevealStep currentStep;
  final bool hasSeenCurrentRole;

  const RoleRevealState({
    required this.game,
    required this.gamePlayers,
    required this.settings,
    this.currentPlayerIndex = 0,
    this.currentStep = RevealStep.handover,
    this.hasSeenCurrentRole = false,
  });

  GamePlayer? get currentPlayer =>
      (currentPlayerIndex >= 0 && currentPlayerIndex < gamePlayers.length)
          ? gamePlayers[currentPlayerIndex]
          : null;

  bool get isLastPlayer =>
      currentPlayerIndex >= gamePlayers.length - 1;

  List<String> get mafiaTeammates {
    if (!settings.mafiaSeeEachOther) return [];
    final current = currentPlayer;
    if (current == null || current.roleTeam != 'mafia') return [];

    return gamePlayers
        .where((gp) => gp.roleTeam == 'mafia' && gp.id != current.id)
        .map((gp) => '${gp.displayNameSnapshot} (${gp.roleName})')
        .toList();
  }

  RoleRevealState copyWith({
    Game? game,
    List<GamePlayer>? gamePlayers,
    GameSettings? settings,
    int? currentPlayerIndex,
    RevealStep? currentStep,
    bool? hasSeenCurrentRole,
  }) {
    return RoleRevealState(
      game: game ?? this.game,
      gamePlayers: gamePlayers ?? this.gamePlayers,
      settings: settings ?? this.settings,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      currentStep: currentStep ?? this.currentStep,
      hasSeenCurrentRole: hasSeenCurrentRole ?? this.hasSeenCurrentRole,
    );
  }

  @override
  List<Object?> get props => [
        game,
        gamePlayers,
        settings,
        currentPlayerIndex,
        currentStep,
        hasSeenCurrentRole,
      ];
}

class RoleRevealCubit extends Cubit<RoleRevealState> {
  RoleRevealCubit({
    required Game game,
    required List<GamePlayer> gamePlayers,
    required GameSettings settings,
  }) : super(RoleRevealState(
          game: game,
          gamePlayers: gamePlayers,
          settings: settings,
        ));

  void startChoosing() {
    emit(state.copyWith(
      currentStep: RevealStep.choosing,
      hasSeenCurrentRole: false,
    ));
  }

  void markCurrentRevealed() {
    emit(state.copyWith(hasSeenCurrentRole: true));
  }

  void passToNext() {
    if (state.isLastPlayer) {
      // Transition to final moderator cheatsheet page!
      emit(state.copyWith(
        currentStep: RevealStep.moderatorSummary,
      ));
    } else {
      // Advance to next player's handover screen
      emit(state.copyWith(
        currentPlayerIndex: state.currentPlayerIndex + 1,
        currentStep: RevealStep.handover,
        hasSeenCurrentRole: false,
      ));
    }
  }
}
