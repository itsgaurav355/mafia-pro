import '../entities/role.dart';
import 'role_behavior.dart';

class MafiaRole extends RoleBehavior {
  @override
  String get key => 'mafia';

  @override
  String get name => 'Mafia';

  @override
  RoleTeam get team => RoleTeam.mafia;

  @override
  int get nightOrder => 10;

  @override
  bool get hasNightAction => true;

  @override
  String get description =>
      'Enforcer of the syndicate. Knows fellow Mafia members and votes together each night on who to kill.';

  @override
  String get moderatorPrompt =>
      'Mafia Syndicate, open your eyes. Agree on one victim to eliminate.';
}
