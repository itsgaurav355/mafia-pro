import 'package:equatable/equatable.dart';

const Object _sentinel = Object();

class Player extends Equatable {
  final int? id;
  final String name;
  final String? nickname;
  final int color;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? lastPlayedAt;
  final int sortOrder;

  const Player({
    this.id,
    required this.name,
    this.nickname,
    required this.color,
    this.isDeleted = false,
    required this.createdAt,
    this.lastPlayedAt,
    this.sortOrder = 0,
  });

  String get displayName => (nickname != null && nickname!.trim().isNotEmpty)
      ? '$name "$nickname"'
      : name;

  Player copyWith({
    int? id,
    String? name,
    Object? nickname = _sentinel,
    int? color,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? lastPlayedAt,
    int? sortOrder,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      nickname: identical(nickname, _sentinel)
          ? this.nickname
          : (nickname as String?),
      color: color ?? this.color,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'nickname': nickname,
      'color': color,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'last_played_at': lastPlayedAt?.toIso8601String(),
      'sort_order': sortOrder,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as int?,
      name: map['name'] as String,
      nickname: map['nickname'] as String?,
      color: map['color'] as int,
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastPlayedAt: map['last_played_at'] != null
          ? DateTime.parse(map['last_played_at'] as String)
          : null,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name, nickname, color, isDeleted, createdAt, lastPlayedAt, sortOrder];
}
