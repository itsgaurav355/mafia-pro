import 'package:equatable/equatable.dart';

enum RoleTeam {
  mafia,
  town,
  neutral;

  static RoleTeam fromString(String val) {
    switch (val.toLowerCase()) {
      case 'mafia':
        return RoleTeam.mafia;
      case 'town':
        return RoleTeam.town;
      case 'neutral':
      default:
        return RoleTeam.neutral;
    }
  }

  String get value {
    switch (this) {
      case RoleTeam.mafia:
        return 'mafia';
      case RoleTeam.town:
        return 'town';
      case RoleTeam.neutral:
        return 'neutral';
    }
  }

  String get displayName {
    switch (this) {
      case RoleTeam.mafia:
        return 'Mafia Syndicate';
      case RoleTeam.town:
        return 'Town Alliance';
      case RoleTeam.neutral:
        return 'Neutral Rogue';
    }
  }
}

class Role extends Equatable {
  final int? id;
  final String key;
  final String name;
  final RoleTeam team;
  final int nightOrder;
  final bool hasNightAction;
  final bool isBuiltin;
  final bool defaultEnabled;
  final int defaultCount;
  final String description;

  const Role({
    this.id,
    required this.key,
    required this.name,
    required this.team,
    required this.nightOrder,
    required this.hasNightAction,
    this.isBuiltin = true,
    this.defaultEnabled = true,
    this.defaultCount = 1,
    required this.description,
  });

  Role copyWith({
    int? id,
    String? key,
    String? name,
    RoleTeam? team,
    int? nightOrder,
    bool? hasNightAction,
    bool? isBuiltin,
    bool? defaultEnabled,
    int? defaultCount,
    String? description,
  }) {
    return Role(
      id: id ?? this.id,
      key: key ?? this.key,
      name: name ?? this.name,
      team: team ?? this.team,
      nightOrder: nightOrder ?? this.nightOrder,
      hasNightAction: hasNightAction ?? this.hasNightAction,
      isBuiltin: isBuiltin ?? this.isBuiltin,
      defaultEnabled: defaultEnabled ?? this.defaultEnabled,
      defaultCount: defaultCount ?? this.defaultCount,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'key': key,
      'name': name,
      'team': team.value,
      'night_order': nightOrder,
      'has_night_action': hasNightAction ? 1 : 0,
      'is_builtin': isBuiltin ? 1 : 0,
      'default_enabled': defaultEnabled ? 1 : 0,
      'default_count': defaultCount,
    };
  }

  factory Role.fromMap(Map<String, dynamic> map, {String? customDescription}) {
    return Role(
      id: map['id'] as int?,
      key: map['key'] as String,
      name: map['name'] as String,
      team: RoleTeam.fromString(map['team'] as String),
      nightOrder: map['night_order'] as int? ?? 0,
      hasNightAction: (map['has_night_action'] as int? ?? 0) == 1,
      isBuiltin: (map['is_builtin'] as int? ?? 1) == 1,
      defaultEnabled: (map['default_enabled'] as int? ?? 1) == 1,
      defaultCount: map['default_count'] as int? ?? 1,
      description: customDescription ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        key,
        name,
        team,
        nightOrder,
        hasNightAction,
        isBuiltin,
        defaultEnabled,
        defaultCount,
        description,
      ];
}
