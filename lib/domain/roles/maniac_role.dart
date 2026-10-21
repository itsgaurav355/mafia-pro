import '../entities/role.dart';
import 'role_behavior.dart';

class ManiacRole extends RoleBehavior {
  @override
  String get key => 'maniac';

  @override
  String get name => 'Maniac';

  @override
  RoleTeam get team => RoleTeam.neutral;

  @override
  int get nightOrder => 12;

  @override
  bool get hasNightAction => true;

  @override
  String get description =>
      'Solitary serial killer. Kills one player each night independently of the Mafia. Wins if they are the last survivor or with only 1 other player alive.';

  @override
  String get moderatorPrompt =>
      'Maniac, open your eyes. Point to your personal victim tonight.';

  @override
  bool get countsAsMafiaForTownWin => false;

  @override
  bool get countsAsMafiaForParity => false;
}
