import '../entities/role.dart';
import 'role_behavior.dart';

class BodyguardRole extends RoleBehavior {
  @override
  String get key => 'bodyguard';

  @override
  String get name => 'Bodyguard';

  @override
  RoleTeam get team => RoleTeam.town;

  @override
  int get nightOrder => 15;

  @override
  bool get hasNightAction => true;

  @override
  String get description =>
      'Noble shield. Protects one player each night. If that player is attacked by the Mafia or Maniac, the Bodyguard dies in their place.';

  @override
  String get moderatorPrompt =>
      'Bodyguard, open your eyes. Point to a player you will guard with your life tonight.';
}
