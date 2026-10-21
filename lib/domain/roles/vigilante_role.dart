import '../entities/role.dart';
import 'role_behavior.dart';

class VigilanteRole extends RoleBehavior {
  @override
  String get key => 'vigilante';

  @override
  String get name => 'Vigilante';

  @override
  RoleTeam get team => RoleTeam.town;

  @override
  int get nightOrder => 40;

  @override
  bool get hasNightAction => true;

  @override
  String get description =>
      'Rogue officer with one lethal bullet. Has a one-time kill ability across the entire game to execute anyone they suspect.';

  @override
  String get moderatorPrompt =>
      'Vigilante, open your eyes. Point to a player to shoot, or shake your head to save your single bullet.';
}
