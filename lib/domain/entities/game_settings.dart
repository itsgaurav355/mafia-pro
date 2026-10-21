import 'dart:convert';
import 'package:equatable/equatable.dart';

class GameSettings extends Equatable {
  final bool revealRoleOnDeath;
  final bool doctorSelfSave;
  final bool consecutiveSaveRule;
  final bool mafiaSeeEachOther;
  final int discussionTimerSeconds;
  final Map<String, int> roleCounts;

  const GameSettings({
    this.revealRoleOnDeath = true,
    this.doctorSelfSave = true,
    this.consecutiveSaveRule = true,
    this.mafiaSeeEachOther = true,
    this.discussionTimerSeconds = 90,
    this.roleCounts = const {},
  });

  GameSettings copyWith({
    bool? revealRoleOnDeath,
    bool? doctorSelfSave,
    bool? consecutiveSaveRule,
    bool? mafiaSeeEachOther,
    int? discussionTimerSeconds,
    Map<String, int>? roleCounts,
  }) {
    return GameSettings(
      revealRoleOnDeath: revealRoleOnDeath ?? this.revealRoleOnDeath,
      doctorSelfSave: doctorSelfSave ?? this.doctorSelfSave,
      consecutiveSaveRule: consecutiveSaveRule ?? this.consecutiveSaveRule,
      mafiaSeeEachOther: mafiaSeeEachOther ?? this.mafiaSeeEachOther,
      discussionTimerSeconds: discussionTimerSeconds ?? this.discussionTimerSeconds,
      roleCounts: roleCounts ?? this.roleCounts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reveal_role_on_death': revealRoleOnDeath,
      'doctor_self_save': doctorSelfSave,
      'consecutive_save_rule': consecutiveSaveRule,
      'mafia_see_each_other': mafiaSeeEachOther,
      'discussion_timer_seconds': discussionTimerSeconds,
      'role_counts': roleCounts,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory GameSettings.fromMap(Map<String, dynamic> map) {
    return GameSettings(
      revealRoleOnDeath: map['reveal_role_on_death'] as bool? ?? true,
      doctorSelfSave: map['doctor_self_save'] as bool? ?? true,
      consecutiveSaveRule: map['consecutive_save_rule'] as bool? ?? true,
      mafiaSeeEachOther: map['mafia_see_each_other'] as bool? ?? true,
      discussionTimerSeconds: map['discussion_timer_seconds'] as int? ?? 90,
      roleCounts: (map['role_counts'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          {},
    );
  }

  factory GameSettings.fromJson(String source) {
    try {
      return GameSettings.fromMap(jsonDecode(source) as Map<String, dynamic>);
    } catch (_) {
      return const GameSettings();
    }
  }

  @override
  List<Object?> get props => [
        revealRoleOnDeath,
        doctorSelfSave,
        consecutiveSaveRule,
        mafiaSeeEachOther,
        discussionTimerSeconds,
        roleCounts,
      ];
}
