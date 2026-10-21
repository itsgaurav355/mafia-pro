import '../entities/role.dart';
import 'role_behavior.dart';

class CivilianRole extends RoleBehavior {
  @override
  String get key => 'civilian';

  @override
  String get name => 'Civilian';

  @override
  RoleTeam get team => RoleTeam.town;

  @override
  int get nightOrder => 0;

  @override
  bool get hasNightAction => false;

  @override
  String get description =>
      'Ordinary resident of the city. No night abilities, but holds crucial voting power during town discussions.';

  @override
  String get moderatorPrompt => '';
}
