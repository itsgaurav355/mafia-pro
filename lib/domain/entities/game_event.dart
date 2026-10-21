import 'package:equatable/equatable.dart';

class GameEventType {
  static const String nightAction = 'night_action';
  static const String nightResolved = 'night_resolved';
  static const String dayVote = 'day_vote';
  static const String daySkip = 'day_skip';
  static const String elimination = 'elimination';
  static const String gameEnd = 'game_end';
}

class GameEvent extends Equatable {
  final int? id;
  final int gameId;
  final int round;
  final String phase; // 'night' or 'day'
  final String eventType;
  final int? actorGamePlayerId;
  final int? targetGamePlayerId;
  final String? result; // details, e.g. "killed", "saved", "blocked", "innocent", "mafia"
  final DateTime createdAt;

  // Transient names for easy display
  final String? actorName;
  final String? targetName;
  final String? actorRoleName;

  const GameEvent({
    this.id,
    required this.gameId,
    required this.round,
    required this.phase,
    required this.eventType,
    this.actorGamePlayerId,
    this.targetGamePlayerId,
    this.result,
    required this.createdAt,
    this.actorName,
    this.targetName,
    this.actorRoleName,
  });

  GameEvent copyWith({
    int? id,
    int? gameId,
    int? round,
    String? phase,
    String? eventType,
    int? actorGamePlayerId,
    int? targetGamePlayerId,
    String? result,
    DateTime? createdAt,
    String? actorName,
    String? targetName,
    String? actorRoleName,
  }) {
    return GameEvent(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      round: round ?? this.round,
      phase: phase ?? this.phase,
      eventType: eventType ?? this.eventType,
      actorGamePlayerId: actorGamePlayerId ?? this.actorGamePlayerId,
      targetGamePlayerId: targetGamePlayerId ?? this.targetGamePlayerId,
      result: result ?? this.result,
      createdAt: createdAt ?? this.createdAt,
      actorName: actorName ?? this.actorName,
      targetName: targetName ?? this.targetName,
      actorRoleName: actorRoleName ?? this.actorRoleName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'game_id': gameId,
      'round': round,
      'phase': phase,
      'event_type': eventType,
      'actor_game_player_id': actorGamePlayerId,
      'target_game_player_id': targetGamePlayerId,
      'result': result,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GameEvent.fromMap(Map<String, dynamic> map, {
    String? actorName,
    String? targetName,
    String? actorRoleName,
  }) {
    return GameEvent(
      id: map['id'] as int?,
      gameId: map['game_id'] as int,
      round: map['round'] as int,
      phase: map['phase'] as String,
      eventType: map['event_type'] as String,
      actorGamePlayerId: map['actor_game_player_id'] as int?,
      targetGamePlayerId: map['target_game_player_id'] as int?,
      result: map['result'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      actorName: actorName,
      targetName: targetName,
      actorRoleName: actorRoleName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        gameId,
        round,
        phase,
        eventType,
        actorGamePlayerId,
        targetGamePlayerId,
        result,
        createdAt,
      ];
}
