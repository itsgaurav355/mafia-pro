import 'package:equatable/equatable.dart';

class GamePlayer extends Equatable {
  final int? id;
  final int gameId;
  final int playerId;
  final int roleId;
  final String displayNameSnapshot;
  final bool isAlive;
  final int? eliminatedRound;
  final String? eliminatedBy; // 'night_kill', 'vote', 'vigilante', 'maniac', 'bodyguard_sacrifice'

  // Additional transient/enriched fields for presentation and engine logic
  final String? roleKey;
  final String? roleName;
  final String? roleTeam;
  final int? avatarColor;

  const GamePlayer({
    this.id,
    required this.gameId,
    required this.playerId,
    required this.roleId,
    required this.displayNameSnapshot,
    this.isAlive = true,
    this.eliminatedRound,
    this.eliminatedBy,
    this.roleKey,
    this.roleName,
    this.roleTeam,
    this.avatarColor,
  });

  GamePlayer copyWith({
    int? id,
    int? gameId,
    int? playerId,
    int? roleId,
    String? displayNameSnapshot,
    bool? isAlive,
    int? eliminatedRound,
    String? eliminatedBy,
    String? roleKey,
    String? roleName,
    String? roleTeam,
    int? avatarColor,
  }) {
    return GamePlayer(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      playerId: playerId ?? this.playerId,
      roleId: roleId ?? this.roleId,
      displayNameSnapshot: displayNameSnapshot ?? this.displayNameSnapshot,
      isAlive: isAlive ?? this.isAlive,
      eliminatedRound: eliminatedRound ?? this.eliminatedRound,
      eliminatedBy: eliminatedBy ?? this.eliminatedBy,
      roleKey: roleKey ?? this.roleKey,
      roleName: roleName ?? this.roleName,
      roleTeam: roleTeam ?? this.roleTeam,
      avatarColor: avatarColor ?? this.avatarColor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'game_id': gameId,
      'player_id': playerId,
      'role_id': roleId,
      'display_name_snapshot': displayNameSnapshot,
      'is_alive': isAlive ? 1 : 0,
      'eliminated_round': eliminatedRound,
      'eliminated_by': eliminatedBy,
    };
  }

  factory GamePlayer.fromMap(Map<String, dynamic> map, {
    String? roleKey,
    String? roleName,
    String? roleTeam,
    int? avatarColor,
  }) {
    return GamePlayer(
      id: map['id'] as int?,
      gameId: map['game_id'] as int,
      playerId: map['player_id'] as int? ?? 0,
      roleId: map['role_id'] as int,
      displayNameSnapshot: map['display_name_snapshot'] as String,
      isAlive: (map['is_alive'] as int? ?? 1) == 1,
      eliminatedRound: map['eliminated_round'] as int?,
      eliminatedBy: map['eliminated_by'] as String?,
      roleKey: roleKey ?? map['role_key'] as String?,
      roleName: roleName ?? map['role_name'] as String?,
      roleTeam: roleTeam ?? map['role_team'] as String?,
      avatarColor: avatarColor ?? map['player_color'] as int?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        gameId,
        playerId,
        roleId,
        displayNameSnapshot,
        isAlive,
        eliminatedRound,
        eliminatedBy,
        roleKey,
        roleName,
        roleTeam,
        avatarColor,
      ];
}
