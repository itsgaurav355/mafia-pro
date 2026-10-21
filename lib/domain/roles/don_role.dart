import '../entities/role.dart';
import 'role_behavior.dart';

class DonRole extends RoleBehavior {
  @override
  String get key => 'don';

  @override
  String get name => 'Don';

  @override
  RoleTeam get team => RoleTeam.mafia;

  @override
  int get nightOrder => 10;

  @override
  bool get hasNightAction => true;

  @override
  String get description =>
      'Leader of the Mafia. Casts the decisive vote on who to eliminate each night. Appears innocent to the Commissioner.';

  @override
  String get moderatorPrompt =>
      'Mafia Syndicate, open your eyes. Don and Mafia, silently point to your target.';
}
