import '../entities/role.dart';
import 'role_behavior.dart';

class DetectiveSidekickRole extends RoleBehavior {
  @override
  String get key => 'detective_sidekick';

  @override
  String get name => 'Detective Sidekick';

  @override
  RoleTeam get team => RoleTeam.town;

  @override
  int get nightOrder => 0;

  @override
  bool get hasNightAction => false;

  @override
  String get description =>
      'Apprentice to the Commissioner. Learns the identity of the Commissioner if the Commissioner is killed, carrying on the investigation.';

  @override
  String get moderatorPrompt =>
      'Detective Sidekick awakens passively if the Commissioner has fallen.';
}
