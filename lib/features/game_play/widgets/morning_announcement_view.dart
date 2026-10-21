import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glow_card.dart';
import '../../../core/widgets/player_avatar.dart';
import '../../../core/widgets/role_badge.dart';
import '../../../domain/engine/night_resolver.dart';
import '../../../domain/entities/game_player.dart';

class MorningAnnouncementView extends StatelessWidget {
  final int round;
  final NightResolutionResult? result;
  final List<GamePlayer> allPlayers;
  final bool revealRoleOnDeath;
  final VoidCallback onProceedToDay;

  const MorningAnnouncementView({
    super.key,
    required this.round,
    required this.result,
    required this.allPlayers,
    required this.revealRoleOnDeath,
    required this.onProceedToDay,
  });

  @override
  Widget build(BuildContext context) {
    final playerMap = {for (final p in allPlayers) p.id!: p};
    final eliminatedIds = result?.eliminatedPlayerIds ?? {};
    final hasDeaths = eliminatedIds.isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sun Icon with glowing halo
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    hasDeaths
                        ? AppColors.mafiaGlow.withValues(alpha: 0.3)
                        : AppColors.dayAccent.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasDeaths ? AppColors.mafiaDark : const Color(0xFF7A4800),
                    border: Border.all(
                      color: hasDeaths ? AppColors.mafiaGlow : AppColors.dayAccent,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    hasDeaths ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                    color: hasDeaths ? AppColors.mafiaGlow : AppColors.dayAccent,
                    size: 36,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'DAWN OF DAY $round',
              style: const TextStyle(
                color: AppColors.dayAccent,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              hasDeaths ? 'TRAGEDY IN THE NIGHT' : 'A PEACEFUL MORNING',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 16),

            // Announcement Box
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: hasDeaths
                      ? AppColors.mafia.withValues(alpha: 0.5)
                      : AppColors.success.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              child: Text(
                result?.summaryAnnouncement ?? 'The town awakens.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Casualty cards if any
            if (hasDeaths) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'CASUALTIES ELIMINATED TONIGHT',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...eliminatedIds.map((id) {
                final player = playerMap[id];
                if (player == null) return const SizedBox.shrink();

                final reason = result?.eliminationReasons[id] ?? 'Killed';
                String reasonLabel;
                if (reason == 'bodyguard_sacrifice') {
                  reasonLabel = 'Sacrificed life for their target!';
                } else if (reason == 'maniac') {
                  reasonLabel = 'Fell victim to the solitary Maniac';
                } else if (reason == 'vigilante') {
                  reasonLabel = 'Struck down by Vigilante bullet';
                } else {
                  reasonLabel = 'Eliminated by Mafia Syndicate';
                }

                return GlowCard(
                  glowColor: AppColors.mafiaGlow,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      PlayerAvatar(
                        name: player.displayNameSnapshot,
                        colorValue: player.avatarColor ?? AppColors.playerAvatarColors[0].toARGB32(),
                        isAlive: false,
                        showAliveStatus: true,
                        radius: 20,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player.displayNameSnapshot,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              reasonLabel,
                              style: const TextStyle(
                                color: AppColors.mafiaGlow,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (revealRoleOnDeath)
                        RoleBadge(
                          roleName: player.roleName ?? 'Unknown',
                          team: player.roleTeam ?? 'town',
                          roleKey: player.roleKey,
                          compact: true,
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],

            // Proceed Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dayAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: onProceedToDay,
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('PROCEED TO DAY DISCUSSION'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
