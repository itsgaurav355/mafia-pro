import '../entities/role.dart';
import 'role_behavior.dart';

class JesterRole extends RoleBehavior {
  @override
  String get key => 'jester';

  @override
  String get name => 'Jester';

  @override
  RoleTeam get team => RoleTeam.neutral;

  @override
  int get nightOrder => 0;

  @override
  bool get hasNightAction => false;

  @override
  String get description =>
      'Deceptive chaotic neutral. Wins alone instantly if the town foolishly votes to execute them during the day phase.';

  @override
  String get moderatorPrompt => '';

  @override
  bool get countsAsMafiaForTownWin => false;

  @override
  bool get countsAsMafiaForParity => false;
}
