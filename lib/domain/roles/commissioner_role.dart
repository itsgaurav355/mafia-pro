import '../entities/role.dart';
import 'role_behavior.dart';

class CommissionerRole extends RoleBehavior {
  @override
  String get key => 'commissioner';

  @override
  String get name => 'Commissioner';

  @override
  RoleTeam get team => RoleTeam.town;

  @override
  int get nightOrder => 30;

  @override
  bool get hasNightAction => true;

  @override
  String get description =>
      'Town investigator. Investigates one player each night to determine if they belong to the Mafia. (Note: The Don will register as innocent).';

  @override
  String get moderatorPrompt =>
      'Commissioner, open your eyes. Point to a player you wish to investigate.';
}
