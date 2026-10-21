import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/engine/night_resolver.dart';
import '../../domain/engine/win_condition_checker.dart';
import '../../domain/entities/game.dart';
import '../../domain/entities/game_event.dart';
import '../../domain/entities/game_player.dart';
import '../../domain/entities/game_settings.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/roles/role_behavior.dart';
import '../../domain/roles/role_registry.dart';

// EVENTS
abstract class GamePlayEvent extends Equatable {
  const GamePlayEvent();
  @override
  List<Object?> get props => [];
}

class GamePlayStarted extends GamePlayEvent {}

class RecordNightAction extends GamePlayEvent {
  final String roleKey;
  final int? targetPlayerId;
  const RecordNightAction({required this.roleKey, this.targetPlayerId});

  @override
  List<Object?> get props => [roleKey, targetPlayerId];
}

class PreviousNightStep extends GamePlayEvent {}

class ResolveNight extends GamePlayEvent {}

class AcknowledgeMorning extends GamePlayEvent {}

class DayEliminatePlayer extends GamePlayEvent {
  final GamePlayer player;
  const DayEliminatePlayer(this.player);

  @override
  List<Object?> get props => [player];
}

class DaySkipElimination extends GamePlayEvent {}

class ConcludeGame extends GamePlayEvent {
  final String winnerTeam;
  const ConcludeGame(this.winnerTeam);

  @override
  List<Object?> get props => [winnerTeam];
}

class UndoLastGamePlayEvent extends GamePlayEvent {}

// STATE
enum GamePlayStatus {
  nightPhase,
  morningAnnouncement,
  dayDiscussion,
  gameOver,
}

class GamePlayState extends Equatable {
  final Game game;
  final List<GamePlayer> gamePlayers;
  final GameSettings settings;
  final GamePlayStatus status;
  final int currentNightRoleIndex;
  final List<RoleBehavior> activeNightRoles;
  final Map<String, int?> currentNightTargets; // roleKey -> targetPlayerId
  final NightResolutionResult? latestNightResult;
  final WinResult winResult;
  final GamePlayer? lastEliminatedPlayer;
  final List<GameEvent> eventHistory;
  final bool vigilanteHasFired;
  final int? lastNightDoctorTargetId;
  final int? lastNightEscortTargetId;

  const GamePlayState({
    required this.game,
    required this.gamePlayers,
    required this.settings,
    this.status = GamePlayStatus.nightPhase,
    this.currentNightRoleIndex = 0,
    this.activeNightRoles = const [],
    this.currentNightTargets = const {},
    this.latestNightResult,
    this.winResult = WinResult.inProgress,
    this.lastEliminatedPlayer,
    this.eventHistory = const [],
    this.vigilanteHasFired = false,
    this.lastNightDoctorTargetId,
    this.lastNightEscortTargetId,
  });

  List<GamePlayer> get livingPlayers =>
      gamePlayers.where((p) => p.isAlive).toList();

  List<GamePlayer> get deadPlayers =>
      gamePlayers.where((p) => !p.isAlive).toList();

  RoleBehavior? get currentNightRole =>
      (currentNightRoleIndex >= 0 && currentNightRoleIndex < activeNightRoles.length)
          ? activeNightRoles[currentNightRoleIndex]
          : null;

  bool get isNightComplete =>
      currentNightRoleIndex >= activeNightRoles.length;

  GamePlayState copyWith({
    Game? game,
    List<GamePlayer>? gamePlayers,
    GameSettings? settings,
    GamePlayStatus? status,
    int? currentNightRoleIndex,
    List<RoleBehavior>? activeNightRoles,
    Map<String, int?>? currentNightTargets,
    NightResolutionResult? latestNightResult,
    WinResult? winResult,
    GamePlayer? lastEliminatedPlayer,
    List<GameEvent>? eventHistory,
    bool? vigilanteHasFired,
    int? lastNightDoctorTargetId,
    int? lastNightEscortTargetId,
  }) {
    return GamePlayState(
      game: game ?? this.game,
      gamePlayers: gamePlayers ?? this.gamePlayers,
      settings: settings ?? this.settings,
      status: status ?? this.status,
      currentNightRoleIndex:
          currentNightRoleIndex ?? this.currentNightRoleIndex,
      activeNightRoles: activeNightRoles ?? this.activeNightRoles,
      currentNightTargets: currentNightTargets ?? this.currentNightTargets,
      latestNightResult: latestNightResult ?? this.latestNightResult,
      winResult: winResult ?? this.winResult,
      lastEliminatedPlayer: lastEliminatedPlayer ?? this.lastEliminatedPlayer,
      eventHistory: eventHistory ?? this.eventHistory,
      vigilanteHasFired: vigilanteHasFired ?? this.vigilanteHasFired,
      lastNightDoctorTargetId:
          lastNightDoctorTargetId ?? this.lastNightDoctorTargetId,
      lastNightEscortTargetId:
          lastNightEscortTargetId ?? this.lastNightEscortTargetId,
    );
  }

  @override
  List<Object?> get props => [
        game,
        gamePlayers,
        settings,
        status,
        currentNightRoleIndex,
        activeNightRoles,
        currentNightTargets,
        latestNightResult,
        winResult,
        lastEliminatedPlayer,
        eventHistory,
        vigilanteHasFired,
        lastNightDoctorTargetId,
        lastNightEscortTargetId,
      ];
}

class GamePlayBloc extends Bloc<GamePlayEvent, GamePlayState> {
  final GameRepository gameRepository;

  GamePlayBloc({
    required this.gameRepository,
    required Game game,
    required List<GamePlayer> gamePlayers,
    required GameSettings settings,
  }) : super(GamePlayState(
          game: game,
          gamePlayers: gamePlayers,
          settings: settings,
        )) {
    on<GamePlayStarted>(_onStarted);
    on<RecordNightAction>(_onRecordNightAction);
    on<PreviousNightStep>(_onPreviousNightStep);
    on<ResolveNight>(_onResolveNight);
    on<AcknowledgeMorning>(_onAcknowledgeMorning);
    on<DayEliminatePlayer>(_onDayEliminatePlayer);
    on<DaySkipElimination>(_onDaySkipElimination);
    on<ConcludeGame>(_onConcludeGame);
    on<UndoLastGamePlayEvent>(_onUndoLastEvent);
  }

  Future<void> _onStarted(
      GamePlayStarted event, Emitter<GamePlayState> emit) async {
    final activeNightRoles = _computeActiveNightRoles(state.gamePlayers);
    final events = await gameRepository.getGameEvents(state.game.id!);

    // Check if vigilante already fired in past events
    final vigilanteFired = events.any((e) =>
        e.eventType == GameEventType.nightAction &&
        e.result == 'vigilante_shot');

    emit(state.copyWith(
      activeNightRoles: activeNightRoles,
      eventHistory: events,
      vigilanteHasFired: vigilanteFired,
    ));
  }

  List<RoleBehavior> _computeActiveNightRoles(List<GamePlayer> players) {
    // Collect roles that have living players
    final livingRoleKeys = players
        .where((p) => p.isAlive)
        .map((p) => p.roleKey)
        .where((key) => key != null)
        .toSet();

    // Mafia and Don group together: if either Don or Mafia is alive, Mafia prompt is active
    final hasLivingMafia = livingRoleKeys.contains('don') || livingRoleKeys.contains('mafia');

    final nightRoles = RoleRegistry.getNightActiveRoles().where((role) {
      if (role.key == 'don' || role.key == 'mafia') {
        return hasLivingMafia;
      }
      return livingRoleKeys.contains(role.key);
    }).toList();

    // Deduplicate mafia/don prompt to single call
    final deduped = <RoleBehavior>[];
    bool mafiaAdded = false;
    for (final r in nightRoles) {
      if (r.key == 'don' || r.key == 'mafia') {
        if (!mafiaAdded) {
          deduped.add(r);
          mafiaAdded = true;
        }
      } else {
        deduped.add(r);
      }
    }

    return deduped;
  }

  void _onRecordNightAction(
      RecordNightAction event, Emitter<GamePlayState> emit) {
    final targets = Map<String, int?>.from(state.currentNightTargets);
    targets[event.roleKey] = event.targetPlayerId;

    final nextIndex = state.currentNightRoleIndex + 1;

    emit(state.copyWith(
      currentNightTargets: targets,
      currentNightRoleIndex: nextIndex,
    ));

    if (nextIndex >= state.activeNightRoles.length) {
      add(ResolveNight());
    }
  }

  void _onPreviousNightStep(
      PreviousNightStep event, Emitter<GamePlayState> emit) {
    if (state.currentNightRoleIndex > 0) {
      emit(state.copyWith(
        currentNightRoleIndex: state.currentNightRoleIndex - 1,
      ));
    }
  }

  Future<void> _onResolveNight(
      ResolveNight event, Emitter<GamePlayState> emit) async {
    final actions = <NightActionTarget>[];

    state.currentNightTargets.forEach((roleKey, targetId) {
      final actor = state.gamePlayers.cast<GamePlayer?>().firstWhere(
            (p) => p?.roleKey == roleKey && (p?.isAlive ?? false),
            orElse: () => null,
          );
      actions.add(NightActionTarget(
        roleKey: roleKey,
        actorGamePlayerId: actor?.id ?? 0,
        targetGamePlayerId: targetId,
      ));
    });

    final resolution = NightResolver.resolve(
      allPlayers: state.gamePlayers,
      nightActions: actions,
      settings: state.settings,
      lastNightDoctorTargetId: state.lastNightDoctorTargetId,
      lastNightEscortTargetId: state.lastNightEscortTargetId,
    );

    // Apply casualties to GamePlayers
    final updatedPlayers = state.gamePlayers.map((gp) {
      if (resolution.eliminatedPlayerIds.contains(gp.id)) {
        return gp.copyWith(
          isAlive: false,
          eliminatedRound: state.game.currentRound,
          eliminatedBy: resolution.eliminationReasons[gp.id] ?? 'night_kill',
        );
      }
      return gp;
    }).toList();

    // Save updated player states in DB
    for (final id in resolution.eliminatedPlayerIds) {
      final dead = updatedPlayers.firstWhere((p) => p.id == id);
      await gameRepository.updateGamePlayer(dead);
    }

    // Record Event in DB
    final nightEvent = GameEvent(
      gameId: state.game.id!,
      round: state.game.currentRound,
      phase: 'night',
      eventType: GameEventType.nightResolved,
      result: resolution.summaryAnnouncement,
      createdAt: DateTime.now(),
    );
    await gameRepository.insertGameEvent(nightEvent);

    // Check Win Condition
    final win = WinConditionChecker.check(allPlayers: updatedPlayers);

    // Record winner if finished
    Game updatedGame = state.game.copyWith(
      currentPhase: GamePhase.day,
      winnerTeam: win.teamKey,
      status: win != WinResult.inProgress ? GameStatus.finished : GameStatus.inProgress,
      endedAt: win != WinResult.inProgress ? DateTime.now() : null,
    );
    await gameRepository.updateGame(updatedGame);

    final events = await gameRepository.getGameEvents(state.game.id!);

    emit(state.copyWith(
      game: updatedGame,
      gamePlayers: updatedPlayers,
      latestNightResult: resolution,
      winResult: win,
      status: GamePlayStatus.morningAnnouncement,
      eventHistory: events,
      vigilanteHasFired: state.vigilanteHasFired || resolution.vigilanteFired,
      lastNightDoctorTargetId: state.currentNightTargets['doctor'],
      lastNightEscortTargetId: state.currentNightTargets['escort'],
      currentNightTargets: {},
      currentNightRoleIndex: 0,
    ));
  }

  void _onAcknowledgeMorning(
      AcknowledgeMorning event, Emitter<GamePlayState> emit) {
    if (state.winResult != WinResult.inProgress) {
      emit(state.copyWith(status: GamePlayStatus.gameOver));
    } else {
      emit(state.copyWith(status: GamePlayStatus.dayDiscussion));
    }
  }

  Future<void> _onDayEliminatePlayer(
      DayEliminatePlayer event, Emitter<GamePlayState> emit) async {
    final eliminated = event.player.copyWith(
      isAlive: false,
      eliminatedRound: state.game.currentRound,
      eliminatedBy: 'vote',
    );
    await gameRepository.updateGamePlayer(eliminated);

    final updatedPlayers = state.gamePlayers.map((p) {
      return p.id == eliminated.id ? eliminated : p;
    }).toList();

    // Check if Jester was executed
    final isJester = eliminated.roleKey == 'jester';

    // Record vote event
    final voteEvent = GameEvent(
      gameId: state.game.id!,
      round: state.game.currentRound,
      phase: 'day',
      eventType: GameEventType.dayVote,
      targetGamePlayerId: eliminated.id,
      targetName: eliminated.displayNameSnapshot,
      result: 'Eliminated by town vote',
      createdAt: DateTime.now(),
    );
    await gameRepository.insertGameEvent(voteEvent);

    // Win condition check
    final win = WinConditionChecker.check(
      allPlayers: updatedPlayers,
      jesterExecutedToday: isJester,
    );

    final nextRound = state.game.currentRound + 1;
    final updatedGame = state.game.copyWith(
      currentRound: win != WinResult.inProgress ? state.game.currentRound : nextRound,
      currentPhase: GamePhase.night,
      winnerTeam: win.teamKey,
      status: win != WinResult.inProgress ? GameStatus.finished : GameStatus.inProgress,
      endedAt: win != WinResult.inProgress ? DateTime.now() : null,
    );
    await gameRepository.updateGame(updatedGame);

    final events = await gameRepository.getGameEvents(state.game.id!);
    final activeNightRoles = _computeActiveNightRoles(updatedPlayers);

    emit(state.copyWith(
      game: updatedGame,
      gamePlayers: updatedPlayers,
      lastEliminatedPlayer: eliminated,
      winResult: win,
      status: win != WinResult.inProgress ? GamePlayStatus.gameOver : GamePlayStatus.nightPhase,
      eventHistory: events,
      activeNightRoles: activeNightRoles,
      currentNightRoleIndex: 0,
      currentNightTargets: {},
    ));
  }

  Future<void> _onDaySkipElimination(
      DaySkipElimination event, Emitter<GamePlayState> emit) async {
    final skipEvent = GameEvent(
      gameId: state.game.id!,
      round: state.game.currentRound,
      phase: 'day',
      eventType: GameEventType.daySkip,
      result: 'Town spared everyone. No elimination.',
      createdAt: DateTime.now(),
    );
    await gameRepository.insertGameEvent(skipEvent);

    final nextRound = state.game.currentRound + 1;
    final updatedGame = state.game.copyWith(
      currentRound: nextRound,
      currentPhase: GamePhase.night,
    );
    await gameRepository.updateGame(updatedGame);

    final events = await gameRepository.getGameEvents(state.game.id!);
    final activeNightRoles = _computeActiveNightRoles(state.gamePlayers);

    emit(state.copyWith(
      game: updatedGame,
      status: GamePlayStatus.nightPhase,
      eventHistory: events,
      activeNightRoles: activeNightRoles,
      currentNightRoleIndex: 0,
      currentNightTargets: {},
    ));
  }

  Future<void> _onUndoLastEvent(
      UndoLastGamePlayEvent event, Emitter<GamePlayState> emit) async {
    await gameRepository.deleteLatestEvent(state.game.id!);
    // Refresh players and events from repository
    final freshPlayers = await gameRepository.getGamePlayers(state.game.id!);
    final events = await gameRepository.getGameEvents(state.game.id!);

    emit(state.copyWith(
      gamePlayers: freshPlayers,
      eventHistory: events,
    ));
  }

  Future<void> _onConcludeGame(
      ConcludeGame event, Emitter<GamePlayState> emit) async {
    final win = WinResult.fromTeamKey(event.winnerTeam);
    final updatedGame = state.game.copyWith(
      winnerTeam: event.winnerTeam,
      status: GameStatus.finished,
      endedAt: DateTime.now(),
    );
    await gameRepository.updateGame(updatedGame);

    final concludeEvent = GameEvent(
      gameId: state.game.id!,
      round: state.game.currentRound,
      phase: state.game.currentPhase.value,
      eventType: 'manual_conclusion',
      result: 'Moderator concluded match: ${event.winnerTeam.toUpperCase()} victory.',
      createdAt: DateTime.now(),
    );
    await gameRepository.insertGameEvent(concludeEvent);

    final events = await gameRepository.getGameEvents(state.game.id!);

    emit(state.copyWith(
      game: updatedGame,
      winResult: win,
      status: GamePlayStatus.gameOver,
      eventHistory: events,
    ));
  }
}
