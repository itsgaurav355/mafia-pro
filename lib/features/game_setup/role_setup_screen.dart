import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/game_constants.dart';
import '../../core/di/service_locator.dart';
import '../../core/widgets/atmospheric_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/role_badge.dart';
import '../../domain/engine/role_distributor.dart';
import '../../domain/entities/game.dart';
import '../../domain/entities/player.dart';
import '../../domain/entities/role.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/repositories/player_repository.dart';
import '../role_reveal/role_reveal_cubit.dart';
import '../role_reveal/role_reveal_screen.dart';
import 'game_setup_cubit.dart';

class RoleSetupScreen extends StatelessWidget {
  const RoleSetupScreen({super.key});

  void _onDealRoles(BuildContext context, GameSetupState state) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      final gameRepo = getIt<GameRepository>();
      final playerRepo = getIt<PlayerRepository>();

      // 1. Create Game in database
      final newGame = Game(
        startedAt: DateTime.now(),
        status: GameStatus.reveal,
        currentRound: 1,
        currentPhase: GamePhase.night,
        settings: state.settings.copyWith(roleCounts: state.roleCounts),
      );
      final gameId = await gameRepo.createGame(newGame);

      // 2. Map available roles
      final rolesMap = {for (final r in state.allRoles) r.key: r};

      // 3. Resolve all participants (assign real database IDs for guests to satisfy foreign keys)
      final rawParticipants = state.allParticipatingPlayers;
      final participants = <Player>[];
      for (final p in rawParticipants) {
        if (p.id != null && p.id! > 0) {
          participants.add(p);
        } else {
          var dbPlayer = await playerRepo.getPlayerByName(p.name);
          if (dbPlayer == null) {
            try {
              final guestId = await playerRepo.insertPlayer(Player(
                name: p.name,
                color: p.color,
                isDeleted: true,
                createdAt: DateTime.now(),
              ));
              dbPlayer = p.copyWith(id: guestId);
            } catch (_) {
              dbPlayer = await playerRepo.getPlayerByName(p.name);
            }
          }
          participants.add(dbPlayer ?? p);
        }
      }

      // 4. Distribute roles cryptographically
      final gamePlayers = RoleDistributor.distributeRoles(
        gameId: gameId,
        players: participants,
        roleCounts: state.roleCounts,
        availableRolesMap: rolesMap,
      );

      // 5. Save game players
      await gameRepo.insertGamePlayers(gamePlayers);

      // 6. Update last_played_at for roster players
      final realPlayerIds = participants
          .where((p) => !p.isDeleted && p.id != null && p.id! > 0)
          .map((p) => p.id!)
          .toList();
      await playerRepo.updateLastPlayed(realPlayerIds, DateTime.now());

      // Fetch saved game players with autoincrement IDs
      final savedGamePlayers = await gameRepo.getGamePlayers(gameId);

      // Navigate to Role Reveal Screen
      nav.pushReplacement(
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => RoleRevealCubit(
              game: newGame.copyWith(id: gameId),
              gamePlayers: savedGamePlayers,
              settings: state.settings,
            ),
            child: const RoleRevealScreen(),
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to deal roles: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AtmosphericBackground(
      mood: AtmosphereMood.noir,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('ROLE SETUP'),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.auto_fix_high_rounded, size: 18, color: AppColors.gold),
              label: const Text(
                'AUTO BALANCE',
                style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700),
              ),
              onPressed: () => context.read<GameSetupCubit>().autoBalanceRoles(),
            ),
          ],
        ),
        bottomNavigationBar: BlocBuilder<GameSetupCubit, GameSetupState>(
          builder: (context, state) {
            final warning = state.balanceWarning;

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (warning != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppColors.warning, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              warning,
                              style: const TextStyle(
                                color: AppColors.warning,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${state.totalAssignedRolesCount} / ${state.totalSelectedCount} ROLES',
                              style: TextStyle(
                                color: state.totalAssignedRolesCount == state.totalSelectedCount
                                    ? AppColors.success
                                    : Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Mafia: ${state.mafiaCount} players',
                              style: TextStyle(
                                color: state.isMafiaCountValid
                                    ? AppColors.mafiaGlow
                                    : AppColors.error,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        onPressed: state.canStartGame ? () => _onDealRoles(context, state) : null,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('DEAL ROLES'),
                            SizedBox(width: 6),
                            Icon(Icons.style_rounded, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        body: BlocBuilder<GameSetupCubit, GameSetupState>(
          builder: (context, state) {
            final roles = state.allRoles;
            final recommended = GameConstants.getRecommendedRoles(
              state.totalSelectedCount,
              enabledRoleKeys: state.enabledRoleKeys,
            );

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: roles.length,
              itemBuilder: (context, index) {
                final role = roles[index];
                final count = state.roleCounts[role.key] ?? 0;
                final isCivilian = role.key == 'civilian';
                final isEnabled = isCivilian ? count > 0 : state.enabledRoleKeys.contains(role.key);
                final suggestedCount = recommended[role.key] ?? 0;

                return GlowCard(
                  isSelected: isEnabled && count > 0,
                  glowColor: isEnabled
                      ? (role.team == RoleTeam.mafia
                          ? AppColors.mafiaGlow
                          : (role.team == RoleTeam.town
                              ? AppColors.townGlow
                              : AppColors.neutralGlow))
                      : null,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          RoleBadge(
                            roleName: role.name,
                            team: role.team.value,
                            roleKey: role.key,
                            compact: true,
                          ),
                          const Spacer(),
                          if (isCivilian) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.townGlow.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.townGlow.withValues(alpha: 0.5)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.sync_rounded, color: AppColors.townGlow, size: 13),
                                  SizedBox(width: 4),
                                  Text(
                                    'AUTO-BALANCED',
                                    style: TextStyle(
                                      color: AppColors.townGlow,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            if (suggestedCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceBorder,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Suggested: $suggestedCount',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            Switch(
                              value: isEnabled,
                              activeThumbColor: AppColors.mafiaGlow,
                              onChanged: (val) => context
                                  .read<GameSetupCubit>()
                                  .toggleRoleEnabled(role.key, val),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isCivilian
                            ? (count > 0
                                ? 'Ordinary resident. Automatically assigned to all $count remaining players based on other active roles.'
                                : 'All player slots are currently filled by special roles.')
                            : role.description,
                        style: TextStyle(
                          color: isCivilian && count == 0 ? AppColors.warning : AppColors.textMuted,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      if (isCivilian) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: count > 0
                                    ? AppColors.townGlow.withValues(alpha: 0.12)
                                    : AppColors.surfaceBorder,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$count REMAINING SLOTS',
                                style: TextStyle(
                                  color: count > 0 ? AppColors.townGlow : AppColors.textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (isEnabled) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'COUNT:',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Minus button
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceBorder,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.remove, size: 18),
                                color: count > 0 ? Colors.white : AppColors.textMuted,
                                onPressed: count > 0
                                    ? () => context
                                        .read<GameSetupCubit>()
                                        .setRoleCount(role.key, count - 1)
                                    : null,
                              ),
                            ),
                            Container(
                              width: 44,
                              alignment: Alignment.center,
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            // Plus button
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceBorder,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.add, size: 18),
                                color: Colors.white,
                                onPressed: () => context
                                    .read<GameSetupCubit>()
                                    .setRoleCount(role.key, count + 1),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
