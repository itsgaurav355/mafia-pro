import '../entities/role.dart';
import 'role_behavior.dart';

class EscortRole extends RoleBehavior {
  @override
  String get key => 'escort';

  @override
  String get name => 'Escort';

  @override
  RoleTeam get team => RoleTeam.town;

  @override
  int get nightOrder => 5;

  @override
  bool get hasNightAction => true;

  @override
  String get description =>
      'Charming distractor. Visits one player at the start of the night, blocking their night action completely.';

  @override
  String get moderatorPrompt =>
      'Escort, open your eyes. Point to a player you will distract tonight.';
}
