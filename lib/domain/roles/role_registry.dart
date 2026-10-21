import 'bodyguard_role.dart';
import 'civilian_role.dart';
import 'commissioner_role.dart';
import 'detective_sidekick_role.dart';
import 'doctor_role.dart';
import 'don_role.dart';
import 'escort_role.dart';
import 'jester_role.dart';
import 'mafia_role.dart';
import 'maniac_role.dart';
import 'role_behavior.dart';
import 'vigilante_role.dart';

class RoleRegistry {
  static final Map<String, RoleBehavior> _roles = {
    'don': DonRole(),
    'mafia': MafiaRole(),
    'commissioner': CommissionerRole(),
    'doctor': DoctorRole(),
    'detective_sidekick': DetectiveSidekickRole(),
    'vigilante': VigilanteRole(),
    'civilian': CivilianRole(),
    'jester': JesterRole(),
    'bodyguard': BodyguardRole(),
    'escort': EscortRole(),
    'maniac': ManiacRole(),
  };

  static RoleBehavior? get(String key) => _roles[key.toLowerCase()];

  static List<RoleBehavior> getAll() => _roles.values.toList();

  static List<RoleBehavior> getNightActiveRoles() {
    final list = _roles.values.where((r) => r.hasNightAction).toList();
    list.sort((a, b) => a.nightOrder.compareTo(b.nightOrder));
    return list;
  }
}
