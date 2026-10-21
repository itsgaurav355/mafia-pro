class GameConstants {
  static const int minPlayers = 4;
  static const int maxPlayers = 30;

  // Rule settings keys
  static const String keyRevealRoleOnDeath = 'reveal_role_on_death';
  static const String keyDoctorSelfSave = 'doctor_self_save';
  static const String keyConsecutiveSaveRule = 'consecutive_save_rule';
  static const String keyMafiaSeeEachOther = 'mafia_see_each_other';
  static const String keyDiscussionTimerSeconds = 'discussion_timer_seconds';
  static const String keyHasSeenOnboarding = 'has_seen_onboarding';

  // Role keys
  static const String roleDon = 'don';
  static const String roleMafia = 'mafia';
  static const String roleCommissioner = 'commissioner';
  static const String roleDoctor = 'doctor';
  static const String roleDetectiveSidekick = 'detective_sidekick';
  static const String roleVigilante = 'vigilante';
  static const String roleCivilian = 'civilian';
  static const String roleJester = 'jester';
  static const String roleBodyguard = 'bodyguard';
  static const String roleEscort = 'escort';
  static const String roleManiac = 'maniac';

  // Priority order to fill optional special roles when enabled (PRD Section 3)
  static const List<String> specialRolesPriorityOrder = [
    roleVigilante,
    roleBodyguard,
    roleEscort,
    roleDetectiveSidekick,
    roleJester,
    roleManiac,
  ];

  /// Recommended role distribution based on PRD Section 3 table
  static Map<String, int> getRecommendedRoles(int playerCount, {Set<String>? enabledRoleKeys}) {
    final enabled = enabledRoleKeys ?? {
      roleDon,
      roleMafia,
      roleCommissioner,
      roleDoctor,
      roleCivilian,
    };

    final result = <String, int>{};
    for (final key in [
      roleDon,
      roleMafia,
      roleCommissioner,
      roleDoctor,
      roleCivilian,
      roleDetectiveSidekick,
      roleVigilante,
      roleJester,
      roleBodyguard,
      roleEscort,
      roleManiac,
    ]) {
      result[key] = 0;
    }

    if (playerCount < minPlayers) return result;

    int mafiaTotal;
    int commCount = enabled.contains(roleCommissioner) ? 1 : 0;
    int docCount = 0;
    int maxSpecial = 0;

    if (playerCount <= 5) {
      mafiaTotal = 1;
      docCount = enabled.contains(roleDoctor) ? 1 : 0;
      maxSpecial = 0;
    } else if (playerCount <= 7) {
      mafiaTotal = 2;
      docCount = enabled.contains(roleDoctor) ? 1 : 0;
      maxSpecial = 1;
    } else if (playerCount <= 10) {
      mafiaTotal = 3;
      docCount = enabled.contains(roleDoctor) ? 1 : 0;
      maxSpecial = 2;
    } else if (playerCount <= 14) {
      mafiaTotal = 4;
      docCount = enabled.contains(roleDoctor) ? 1 : 0;
      maxSpecial = 3;
    } else if (playerCount <= 20) {
      mafiaTotal = 5;
      docCount = enabled.contains(roleDoctor) ? 1 : 0;
      maxSpecial = 4;
    } else {
      mafiaTotal = 7;
      docCount = enabled.contains(roleDoctor) ? 1 : 0;
      maxSpecial = 5;
    }

    // Distribute mafia: 1 Don + (mafiaTotal - 1) Mafia members
    if (enabled.contains(roleDon)) {
      result[roleDon] = 1;
      if (enabled.contains(roleMafia)) {
        result[roleMafia] = (mafiaTotal - 1).clamp(0, playerCount);
      }
    } else if (enabled.contains(roleMafia)) {
      result[roleMafia] = mafiaTotal;
    }

    result[roleCommissioner] = commCount;
    result[roleDoctor] = docCount;

    // Distribute special roles in order
    int specialSlotsAssigned = 0;
    for (final specialKey in specialRolesPriorityOrder) {
      if (specialSlotsAssigned >= maxSpecial) break;
      if (enabled.contains(specialKey)) {
        result[specialKey] = 1;
        specialSlotsAssigned++;
      }
    }

    // Remaining slots go to Civilians
    int currentSum = result.values.fold(0, (a, b) => a + b);
    int civilianSlots = playerCount - currentSum;
    if (civilianSlots > 0 && enabled.contains(roleCivilian)) {
      result[roleCivilian] = civilianSlots;
    }

    return result;
  }
}
