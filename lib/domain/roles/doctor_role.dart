import '../entities/role.dart';
import 'role_behavior.dart';

class DoctorRole extends RoleBehavior {
  @override
  String get key => 'doctor';

  @override
  String get name => 'Doctor';

  @override
  RoleTeam get team => RoleTeam.town;

  @override
  int get nightOrder => 20;

  @override
  bool get hasNightAction => true;

  @override
  String get description =>
      'Protector of the innocent. Chooses one player each night to shield from death. If that player is attacked, they survive.';

  @override
  String get moderatorPrompt =>
      'Doctor, open your eyes. Point to a player you wish to protect tonight.';
}
