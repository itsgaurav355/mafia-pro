import 'package:equatable/equatable.dart';
import 'game_settings.dart';

enum GameStatus {
  setup,
  reveal,
  inProgress,
  finished;

  static GameStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'reveal':
        return GameStatus.reveal;
      case 'in_progress':
        return GameStatus.inProgress;
      case 'finished':
      case 'archived':
        return GameStatus.finished;
      case 'setup':
      default:
        return GameStatus.setup;
    }
  }

  String get value {
    switch (this) {
      case GameStatus.setup:
        return 'setup';
      case GameStatus.reveal:
        return 'reveal';
      case GameStatus.inProgress:
        return 'in_progress';
      case GameStatus.finished:
        return 'finished';
    }
  }
}

enum GamePhase {
  night,
  day;

  static GamePhase fromString(String val) {
    return val.toLowerCase() == 'day' ? GamePhase.day : GamePhase.night;
  }

  String get value => this == GamePhase.day ? 'day' : 'night';
}

class Game extends Equatable {
  final int? id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final GameStatus status;
  final int currentRound;
  final GamePhase currentPhase;
  final String? winnerTeam; // 'town', 'mafia', 'jester', 'maniac'
  final GameSettings settings;

  const Game({
    this.id,
    required this.startedAt,
    this.endedAt,
    this.status = GameStatus.setup,
    this.currentRound = 1,
    this.currentPhase = GamePhase.night,
    this.winnerTeam,
    required this.settings,
  });

  Game copyWith({
    int? id,
    DateTime? startedAt,
    DateTime? endedAt,
    GameStatus? status,
    int? currentRound,
    GamePhase? currentPhase,
    String? winnerTeam,
    GameSettings? settings,
  }) {
    return Game(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      currentRound: currentRound ?? this.currentRound,
      currentPhase: currentPhase ?? this.currentPhase,
      winnerTeam: winnerTeam ?? this.winnerTeam,
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'status': status.value,
      'current_round': currentRound,
      'current_phase': currentPhase.value,
      'winner_team': winnerTeam,
      'settings_json': settings.toJson(),
    };
  }

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'] as int?,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null ? DateTime.parse(map['ended_at'] as String) : null,
      status: GameStatus.fromString(map['status'] as String),
      currentRound: map['current_round'] as int? ?? 1,
      currentPhase: GamePhase.fromString(map['current_phase'] as String? ?? 'night'),
      winnerTeam: map['winner_team'] as String?,
      settings: GameSettings.fromJson(map['settings_json'] as String? ?? '{}'),
    );
  }

  @override
  List<Object?> get props => [
        id,
        startedAt,
        endedAt,
        status,
        currentRound,
        currentPhase,
        winnerTeam,
        settings,
      ];
}
