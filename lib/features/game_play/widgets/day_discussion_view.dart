import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/countdown_timer_widget.dart';
import '../../../core/widgets/glow_card.dart';
import '../../../core/widgets/player_avatar.dart';
import '../../../domain/entities/game_player.dart';

class DayDiscussionView extends StatelessWidget {
  final int round;
  final int initialTimerSeconds;
  final List<GamePlayer> livingPlayers;
  final Function(GamePlayer player) onEliminatePlayer;
  final VoidCallback onSkipElimination;

  const DayDiscussionView({
    super.key,
    required this.round,
    required this.initialTimerSeconds,
    required this.livingPlayers,
    required this.onEliminatePlayer,
    required this.onSkipElimination,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Discussion Timer
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: CountdownTimerWidget(
            initialSeconds: initialTimerSeconds,
          ),
        ),

        // Voting Headline & Skip Button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'TOWN VOTE (${livingPlayers.length} LIVING)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  side: const BorderSide(color: AppColors.surfaceBorderLight),
                ),
                icon: const Icon(Icons.shield_outlined, size: 15),
                label: const Text('SPARE ALL', style: TextStyle(fontSize: 11)),
                onPressed: () async {
                  final confirm = await ConfirmDialog.show(
                    context: context,
                    title: 'No Elimination Today?',
                    message:
                        'The town failed to reach a majority or chose to spare everyone. Proceed directly to Night ${round + 1}?',
                    confirmText: 'SPARE ALL',
                    confirmColor: AppColors.dayAccent,
                  );
                  if (confirm) onSkipElimination();
                },
              ),
            ],
          ),
        ),

        // Living Players Voting List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            itemCount: livingPlayers.length,
            itemBuilder: (context, index) {
              final player = livingPlayers[index];

              return GlowCard(
                glowColor: AppColors.mafiaGlow,
                margin: const EdgeInsets.symmetric(vertical: 4),
                onTap: () async {
                  final confirm = await ConfirmDialog.show(
                    context: context,
                    title: 'Execute ${player.displayNameSnapshot}?',
                    message:
                        'The town has reached a majority consensus to eliminate ${player.displayNameSnapshot}. Are you sure?',
                    confirmText: 'EXECUTE',
                    confirmColor: AppColors.mafia,
                    icon: Icons.gavel_rounded,
                  );
                  if (confirm) {
                    onEliminatePlayer(player);
                  }
                },
                child: Row(
                  children: [
                    PlayerAvatar(
                      name: player.displayNameSnapshot,
                      colorValue: player.avatarColor ?? AppColors.playerAvatarColors[0].toARGB32(),
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
                          const Text(
                            'Tap to cast town execution vote',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.mafia.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.mafia.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.gavel_rounded, color: AppColors.mafiaGlow, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'VOTE',
                            style: TextStyle(
                              color: AppColors.mafiaGlow,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
