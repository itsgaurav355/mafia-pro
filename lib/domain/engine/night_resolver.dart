import '../entities/game_player.dart';
import '../entities/game_settings.dart';

class NightActionTarget {
  final String roleKey;
  final int actorGamePlayerId;
  final int? targetGamePlayerId;

  const NightActionTarget({
    required this.roleKey,
    required this.actorGamePlayerId,
    this.targetGamePlayerId,
  });
}

class NightResolutionResult {
  final Set<int> eliminatedPlayerIds;
  final Map<int, String> eliminationReasons; // playerId -> reason description
  final Set<int> savedPlayerIds;
  final Map<int, String> commissionerResults; // targetPlayerId -> "MAFIA" or "INNOCENT"
  final bool vigilanteFired;
  final bool sidekickAwakened;
  final String summaryAnnouncement;

  const NightResolutionResult({
    required this.eliminatedPlayerIds,
    required this.eliminationReasons,
    required this.savedPlayerIds,
    required this.commissionerResults,
    required this.vigilanteFired,
    required this.sidekickAwakened,
    required this.summaryAnnouncement,
  });
}

class NightResolver {
  static NightResolutionResult resolve({
    required List<GamePlayer> allPlayers,
    required List<NightActionTarget> nightActions,
    required GameSettings settings,
    int? lastNightDoctorTargetId,
    int? lastNightEscortTargetId,
    bool commissionerAlreadyDead = false,
  }) {
    final playerMap = {for (final p in allPlayers) p.id!: p};
    final actionByRole = {for (final a in nightActions) a.roleKey: a};

    final eliminatedIds = <int>{};
    final eliminationReasons = <int, String>{};
    final savedIds = <int>{};
    final commissionerResults = <int, String>{};
    bool vigilanteFired = false;
    bool sidekickAwakened = false;

    // 1. Resolve Escort (order 5): check who was blocked
    int? blockedPlayerId;
    final escortAction = actionByRole['escort'];
    if (escortAction != null && escortAction.targetGamePlayerId != null) {
      final targetId = escortAction.targetGamePlayerId!;
      // Check consecutive block rule if configured
      if (!settings.consecutiveSaveRule || targetId != lastNightEscortTargetId) {
        blockedPlayerId = targetId;
      }
    }

    // Helper: is actor blocked?
    bool isBlocked(NightActionTarget? action) {
      if (action == null) return false;
      return action.actorGamePlayerId == blockedPlayerId;
    }

    // 2. Resolve Doctor protection (order 20)
    int? doctorTargetId;
    final doctorAction = actionByRole['doctor'];
    if (doctorAction != null && !isBlocked(doctorAction) && doctorAction.targetGamePlayerId != null) {
      final targetId = doctorAction.targetGamePlayerId!;
      final isSelf = targetId == doctorAction.actorGamePlayerId;

      bool canSave = true;
      if (isSelf && !settings.doctorSelfSave) {
        canSave = false;
      }
      if (settings.consecutiveSaveRule && targetId == lastNightDoctorTargetId) {
        canSave = false;
      }

      if (canSave) {
        doctorTargetId = targetId;
        savedIds.add(targetId);
      }
    }

    // 3. Resolve Bodyguard protection (order 15)
    int? bodyguardTargetId;
    int? bodyguardPlayerId;
    final bodyguardAction = actionByRole['bodyguard'];
    if (bodyguardAction != null && !isBlocked(bodyguardAction) && bodyguardAction.targetGamePlayerId != null) {
      bodyguardTargetId = bodyguardAction.targetGamePlayerId!;
      bodyguardPlayerId = bodyguardAction.actorGamePlayerId;
    }

    // Collect attacks
    // A. Mafia attack
    int? mafiaAttackTargetId;
    final mafiaAction = actionByRole['mafia'] ?? actionByRole['don'];
    if (mafiaAction != null && !isBlocked(mafiaAction) && mafiaAction.targetGamePlayerId != null) {
      mafiaAttackTargetId = mafiaAction.targetGamePlayerId;
    }

    // B. Maniac attack
    int? maniacAttackTargetId;
    final maniacAction = actionByRole['maniac'];
    if (maniacAction != null && !isBlocked(maniacAction) && maniacAction.targetGamePlayerId != null) {
      maniacAttackTargetId = maniacAction.targetGamePlayerId;
    }

    // C. Vigilante attack
    int? vigilanteAttackTargetId;
    final vigilanteAction = actionByRole['vigilante'];
    if (vigilanteAction != null && !isBlocked(vigilanteAction) && vigilanteAction.targetGamePlayerId != null) {
      vigilanteAttackTargetId = vigilanteAction.targetGamePlayerId;
      vigilanteFired = true;
    }

    // Process targets attacked
    final attacks = <int, List<String>>{};
    void addAttack(int? targetId, String attackerType) {
      if (targetId == null) return;
      attacks.putIfAbsent(targetId, () => []).add(attackerType);
    }

    addAttack(mafiaAttackTargetId, 'night_kill');
    addAttack(maniacAttackTargetId, 'maniac');
    addAttack(vigilanteAttackTargetId, 'vigilante');

    attacks.forEach((targetId, attackers) {
      // If doctor saved the target, they survive!
      if (targetId == doctorTargetId) {
        // Target is saved by Doctor!
        return;
      }

      // If protected by Bodyguard
      if (targetId == bodyguardTargetId && bodyguardPlayerId != null) {
        // Bodyguard sacrifices life for target!
        eliminatedIds.add(bodyguardPlayerId);
        eliminationReasons[bodyguardPlayerId] = 'bodyguard_sacrifice';
        // Protected target survives
        return;
      }

      // Otherwise target is eliminated
      eliminatedIds.add(targetId);
      eliminationReasons[targetId] = attackers.first;
    });

    // 4. Resolve Commissioner investigation (order 30)
    final commAction = actionByRole['commissioner'];
    if (commAction != null && !isBlocked(commAction) && commAction.targetGamePlayerId != null) {
      final target = playerMap[commAction.targetGamePlayerId!];
      if (target != null) {
        // Don appears innocent to the Commissioner (PRD Section 3 & 10)
        final isMafia = target.roleKey == 'mafia';
        commissionerResults[target.id!] = isMafia ? 'MAFIA' : 'INNOCENT';
      }
    }

    // 5. Check Detective Sidekick trigger
    // If commissioner was eliminated tonight or in a past round
    final commissioner = allPlayers.cast<GamePlayer?>().firstWhere(
          (p) => p?.roleKey == 'commissioner',
          orElse: () => null,
        );
    if (commissioner != null) {
      final commissionerDiedTonight = eliminatedIds.contains(commissioner.id);
      if (commissionerDiedTonight || commissionerAlreadyDead) {
        sidekickAwakened = true;
      }
    }

    // Build human-friendly announcement
    String announcement;
    if (eliminatedIds.isEmpty) {
      announcement = 'A peaceful dawn breaks upon the city. No one was killed tonight!';
    } else {
      final names = eliminatedIds
          .map((id) => playerMap[id]?.displayNameSnapshot ?? 'Unknown')
          .join(', ');
      announcement = 'Tragedy at dawn! The following player(s) did not survive the night: $names.';
    }

    return NightResolutionResult(
      eliminatedPlayerIds: eliminatedIds,
      eliminationReasons: eliminationReasons,
      savedPlayerIds: savedIds,
      commissionerResults: commissionerResults,
      vigilanteFired: vigilanteFired,
      sidekickAwakened: sidekickAwakened,
      summaryAnnouncement: announcement,
    );
  }
}
