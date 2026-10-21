import '../entities/role.dart';

abstract class RoleBehavior {
  String get key;
  String get name;
  RoleTeam get team;
  int get nightOrder;
  bool get hasNightAction;
  String get description;
  String get moderatorPrompt;

  /// Returns true if this role counts as Mafia for town win condition check
  bool get countsAsMafiaForTownWin => team == RoleTeam.mafia;

  /// Returns true if this role counts as Mafia team member for parity win condition
  bool get countsAsMafiaForParity => team == RoleTeam.mafia;

  /// Whether this role can act during the night
  bool canActAtNight(bool isAlive, {bool blocked = false, bool abilityUsed = false}) {
    if (!isAlive || blocked || !hasNightAction) return false;
    return true;
  }
}
