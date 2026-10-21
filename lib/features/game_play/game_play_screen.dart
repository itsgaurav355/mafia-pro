import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/atmospheric_background.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/player_avatar.dart';
import '../../core/widgets/role_badge.dart';
import '../game_over/game_over_screen.dart';
import 'game_play_bloc.dart';
import 'widgets/day_discussion_view.dart';
import 'widgets/morning_announcement_view.dart';
import 'widgets/night_role_prompt_card.dart';

class GamePlayScreen extends StatelessWidget {
  const GamePlayScreen({super.key});

  void _showModeratorMasterPanel(BuildContext context, GamePlayState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.visibility_rounded, color: AppColors.gold, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'MODERATOR MASTER ROSTER',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: state.gamePlayers.length,
                      itemBuilder: (context, idx) {
                        final gp = state.gamePlayers[idx];
                        return GlowCard(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              PlayerAvatar(
                                name: gp.displayNameSnapshot,
                                colorValue: gp.avatarColor ?? AppColors.playerAvatarColors[0].toARGB32(),
                                isAlive: gp.isAlive,
                                showAliveStatus: true,
                                radius: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  gp.displayNameSnapshot,
                                  style: TextStyle(
                                    color: gp.isAlive ? Colors.white : AppColors.textMuted,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    decoration: gp.isAlive ? null : TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                              RoleBadge(
                                roleName: gp.roleName ?? 'Unknown',
                                team: gp.roleTeam ?? 'town',
                                roleKey: gp.roleKey,
                                compact: true,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mafia,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    icon: const Icon(Icons.flag_rounded, size: 20),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'CONCLUDE MATCH / DECLARE WINNER',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showConcludeDialog(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showConcludeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CONCLUDE MATCH & RECORD WINNER',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(sheetCtx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'End this game immediately and save the record to Match History:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _buildWinnerOption(sheetCtx, context, 'Town Victory', 'town', AppColors.townGlow, Icons.security_rounded),
              _buildWinnerOption(sheetCtx, context, 'Mafia Syndicate Victory', 'mafia', AppColors.mafiaGlow, Icons.local_fire_department_rounded),
              _buildWinnerOption(sheetCtx, context, 'Jester Victory', 'jester', AppColors.jester, Icons.theater_comedy_rounded),
              _buildWinnerOption(sheetCtx, context, 'Draw / Stalemate', 'draw', AppColors.textPrimary, Icons.balance_rounded),
              _buildWinnerOption(sheetCtx, context, 'End Without Winner (Archive)', 'archived', AppColors.textMuted, Icons.inventory_2_rounded),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWinnerOption(
    BuildContext sheetCtx,
    BuildContext context,
    String title,
    String teamKey,
    Color color,
    IconData icon,
  ) {
    return GlowCard(
      margin: const EdgeInsets.symmetric(vertical: 4),
      glowColor: color,
      onTap: () {
        Navigator.of(sheetCtx).pop();
        context.read<GamePlayBloc>().add(ConcludeGame(teamKey));
      },
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GamePlayBloc, GamePlayState>(
      listener: (context, state) {
        if (state.status == GamePlayStatus.gameOver) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => GameOverScreen(
                game: state.game,
                allPlayers: state.gamePlayers,
                winResult: state.winResult,
                eventHistory: state.eventHistory,
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        AtmosphereMood mood;
        String phaseTitle;

        switch (state.status) {
          case GamePlayStatus.nightPhase:
            mood = AtmosphereMood.night;
            phaseTitle = 'NIGHT ${state.game.currentRound}';
            break;
          case GamePlayStatus.morningAnnouncement:
            mood = AtmosphereMood.day;
            phaseTitle = 'MORNING ${state.game.currentRound}';
            break;
          case GamePlayStatus.dayDiscussion:
            mood = AtmosphereMood.crimson;
            phaseTitle = 'DAY ${state.game.currentRound}';
            break;
          case GamePlayStatus.gameOver:
            mood = AtmosphereMood.noir;
            phaseTitle = 'GAME OVER';
            break;
        }

        return AtmosphericBackground(
          mood: mood,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(phaseTitle),
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Exit Game',
                onPressed: () async {
                  final confirm = await ConfirmDialog.show(
                    context: context,
                    title: 'Leave Current Game?',
                    message:
                        'Game progress is automatically saved. You can resume this session anytime from the Home screen.',
                    confirmText: 'EXIT TO HOME',
                    confirmColor: AppColors.mafia,
                  );
                  if (confirm && context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
              ),
              actions: [
                // Living count pill
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite_rounded, color: AppColors.error, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${state.livingPlayers.length} Alive',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_red_eye_outlined, color: AppColors.gold),
                  tooltip: 'Moderator Roster',
                  onPressed: () => _showModeratorMasterPanel(context, state),
                ),
              ],
            ),
            body: SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildPhaseContent(context, state),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhaseContent(BuildContext context, GamePlayState state) {
    switch (state.status) {
      case GamePlayStatus.nightPhase:
        final currentRole = state.currentNightRole;
        if (currentRole == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return NightRolePromptCard(
          key: ValueKey('${currentRole.key}_${state.currentNightRoleIndex}'),
          role: currentRole,
          livingPlayers: state.livingPlayers,
          canUndo: state.currentNightRoleIndex > 0,
          vigilanteHasFired: state.vigilanteHasFired,
          lastNightDoctorTargetId: state.lastNightDoctorTargetId,
          lastNightEscortTargetId: state.lastNightEscortTargetId,
          consecutiveSaveRule: state.settings.consecutiveSaveRule,
          doctorSelfSave: state.settings.doctorSelfSave,
          onUndo: () => context.read<GamePlayBloc>().add(PreviousNightStep()),
          onTargetSelected: (targetId) {
            context.read<GamePlayBloc>().add(
                  RecordNightAction(
                    roleKey: currentRole.key,
                    targetPlayerId: targetId,
                  ),
                );
          },
        );

      case GamePlayStatus.morningAnnouncement:
        return MorningAnnouncementView(
          round: state.game.currentRound,
          result: state.latestNightResult,
          allPlayers: state.gamePlayers,
          revealRoleOnDeath: state.settings.revealRoleOnDeath,
          onProceedToDay: () =>
              context.read<GamePlayBloc>().add(AcknowledgeMorning()),
        );

      case GamePlayStatus.dayDiscussion:
        return DayDiscussionView(
          round: state.game.currentRound,
          initialTimerSeconds: state.settings.discussionTimerSeconds,
          livingPlayers: state.livingPlayers,
          onEliminatePlayer: (player) =>
              context.read<GamePlayBloc>().add(DayEliminatePlayer(player)),
          onSkipElimination: () =>
              context.read<GamePlayBloc>().add(DaySkipElimination()),
        );

      case GamePlayStatus.gameOver:
        return const Center(child: CircularProgressIndicator());
    }
  }
}
