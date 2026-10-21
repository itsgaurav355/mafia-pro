import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import '../../core/widgets/atmospheric_background.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hold_to_reveal.dart';
import '../../core/widgets/player_avatar.dart';
import '../../core/widgets/role_badge.dart';
import '../../domain/entities/game.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/roles/role_registry.dart';
import '../game_play/game_play_bloc.dart';
import '../game_play/game_play_screen.dart';
import 'role_reveal_cubit.dart';

class RoleRevealScreen extends StatelessWidget {
  const RoleRevealScreen({super.key});

  void _onStartNightPhase(BuildContext context, RoleRevealState state) async {
    final gameRepo = getIt<GameRepository>();
    final nav = Navigator.of(context);

    final updatedGame = state.game.copyWith(
      status: GameStatus.inProgress,
      currentRound: 1,
      currentPhase: GamePhase.night,
    );
    await gameRepo.updateGame(updatedGame);

    nav.pushReplacement(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => GamePlayBloc(
            gameRepository: gameRepo,
            game: updatedGame,
            gamePlayers: state.gamePlayers,
            settings: state.settings,
          )..add(GamePlayStarted()),
          child: const GamePlayScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoleRevealCubit, RoleRevealState>(
      builder: (context, state) {
        if (state.currentStep == RevealStep.moderatorSummary) {
          return _buildModeratorLastPage(context, state);
        }

        final current = state.currentPlayer;
        if (current == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return AtmosphericBackground(
          mood: AtmosphereMood.night,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                'PLAYER ${state.currentPlayerIndex + 1} OF ${state.gamePlayers.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              automaticallyImplyLeading: false, // Prevent going back!
            ),
            body: SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: state.currentStep == RevealStep.handover
                    ? _buildHandoverView(context, state)
                    : _buildChoosingView(context, state),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Step 1: Hand phone to player screen with "Start Choosing" button
  Widget _buildHandoverView(BuildContext context, RoleRevealState state) {
    final current = state.currentPlayer!;

    return Padding(
      key: ValueKey('handover_${current.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Pass phone icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceElevated,
              border: Border.all(color: AppColors.surfaceBorderLight, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.phone_android_rounded,
              color: AppColors.townGlow,
              size: 48,
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            'PASS THE PHONE TO',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(height: 10),

          // Player Avatar and Name
          PlayerAvatar(
            name: current.displayNameSnapshot,
            colorValue: current.avatarColor ?? AppColors.playerAvatarColors[0].toARGB32(),
            radius: 36,
          ),

          const SizedBox(height: 14),

          Text(
            current.displayNameSnapshot,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Keep the screen away from other players.\nOnly tap the button below when you are holding the phone.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.45,
            ),
          ),

          const Spacer(),

          // Start Choosing Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.town,
              minimumSize: const Size(double.infinity, 56),
            ),
            onPressed: () => context.read<RoleRevealCubit>().startChoosing(),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fingerprint_rounded, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'I AM ${current.displayNameSnapshot.toUpperCase()} • START CHOOSING',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// Step 2: Secret hold-to-reveal view
  Widget _buildChoosingView(BuildContext context, RoleRevealState state) {
    final current = state.currentPlayer!;
    final roleBehavior = RoleRegistry.get(current.roleKey ?? '');
    final roleDescription =
        roleBehavior?.description ?? 'Act according to your team objectives.';
    final isLast = state.isLastPlayer;

    return Padding(
      key: ValueKey('choosing_${current.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Player greeting
          Text(
            'SECRET ASSIGNMENT FOR ${current.displayNameSnapshot.toUpperCase()}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),

          const Spacer(),

          // Interactive Hold To Reveal
          HoldToReveal(
            playerName: current.displayNameSnapshot,
            roleName: current.roleName ?? 'Unknown',
            roleKey: current.roleKey ?? 'civilian',
            roleTeam: current.roleTeam ?? 'town',
            roleDescription: roleDescription,
            mafiaTeammates: state.mafiaTeammates,
            onRevealedOnce: () =>
                context.read<RoleRevealCubit>().markCurrentRevealed(),
          ),

          const Spacer(),

          // Pass to Next Player button (only active after viewing role)
          Container(
            padding: const EdgeInsets.only(bottom: 20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    state.hasSeenCurrentRole ? AppColors.mafia : AppColors.surfaceBorder,
                foregroundColor:
                    state.hasSeenCurrentRole ? Colors.white : AppColors.textMuted,
                minimumSize: const Size(double.infinity, 54),
              ),
              onPressed: state.hasSeenCurrentRole
                  ? () => context.read<RoleRevealCubit>().passToNext()
                  : null,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.hasSeenCurrentRole
                          ? (isLast
                              ? 'FINISHED • PASS TO MODERATOR'
                              : 'PASS TO NEXT PLAYER')
                          : 'HOLD FINGERPRINT ABOVE TO VIEW ROLE',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    if (state.hasSeenCurrentRole) ...[
                      const SizedBox(width: 8),
                      Icon(
                        isLast
                            ? Icons.security_rounded
                            : Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Step 3: THE LAST PAGE FOR THE MODERATOR WITH THE CHEATSHEET
  Widget _buildModeratorLastPage(BuildContext context, RoleRevealState state) {
    return AtmosphericBackground(
      mood: AtmosphereMood.crimson,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('MODERATOR CHEATSHEET'),
          automaticallyImplyLeading: false,
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mafia,
              minimumSize: const Size(double.infinity, 56),
            ),
            onPressed: () async {
              final confirm = await ConfirmDialog.show(
                context: context,
                title: 'Begin Night 1?',
                message:
                    'All players have received their secret roles. Instruct everyone to close their eyes and start Night 1.',
                confirmText: 'START NIGHT 1',
                confirmColor: AppColors.mafia,
                icon: Icons.nights_stay_rounded,
              );
              if (confirm && context.mounted) {
                _onStartNightPhase(context, state);
              }
            },
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.nights_stay_rounded, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'EVERYONE CLOSE EYES • START NIGHT 1',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            // Moderator Handover Callout
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.6), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.18),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withValues(alpha: 0.18),
                    ),
                    child: const Icon(Icons.security_rounded,
                        color: AppColors.gold, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PHONE RETURNED TO MODERATOR',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'All players have seen their roles. Keep this screen confidential to the host.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'MASTER ROLE ASSIGNMENTS',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),

            const SizedBox(height: 8),

            // Master Roster Cheatsheet
            ...state.gamePlayers.map((gp) {
              return GlowCard(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    PlayerAvatar(
                      name: gp.displayNameSnapshot,
                      colorValue:
                          gp.avatarColor ?? AppColors.playerAvatarColors[0].toARGB32(),
                      radius: 20,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        gp.displayNameSnapshot,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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
            }),
          ],
        ),
      ),
    );
  }
}
