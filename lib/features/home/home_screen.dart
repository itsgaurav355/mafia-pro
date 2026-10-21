import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import '../../core/widgets/app_lottie.dart';
import '../../core/widgets/atmospheric_background.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/glow_card.dart';
import '../../domain/entities/game.dart';
import '../../domain/entities/game_player.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/repositories/player_repository.dart';
import '../../domain/repositories/role_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../game_play/game_play_bloc.dart';
import '../game_play/game_play_screen.dart';
import '../game_setup/game_setup_cubit.dart';
import '../game_setup/select_players_screen.dart';
import '../history/history_cubit.dart';
import '../history/history_screen.dart';
import '../roster/roster_screen.dart';
import '../settings/settings_cubit.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Game? _activeGame;
  List<GamePlayer>? _activeGamePlayers;

  @override
  void initState() {
    super.initState();
    _checkActiveGame();
  }

  Future<void> _checkActiveGame() async {
    final gameRepo = getIt<GameRepository>();
    final active = await gameRepo.getActiveGame();

    if (active != null) {
      final players = await gameRepo.getGamePlayers(active.id!);
      if (mounted) {
        setState(() {
          _activeGame = active;
          _activeGamePlayers = players;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _activeGame = null;
          _activeGamePlayers = null;
        });
      }
    }
  }

  void _resumeActiveGame() async {
    if (_activeGame == null || _activeGamePlayers == null) return;

    final gameRepo = getIt<GameRepository>();
    final settingsRepo = getIt<SettingsRepository>();
    final settings = await settingsRepo.getSettings();

    if (!mounted) return;

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => GamePlayBloc(
                gameRepository: gameRepo,
                game: _activeGame!,
                gamePlayers: _activeGamePlayers!,
                settings: settings,
              )..add(GamePlayStarted()),
              child: const GamePlayScreen(),
            ),
          ),
        )
        .then((_) {
          _checkActiveGame();
          if (mounted) {
            context.read<HistoryCubit>().loadHistory();
          }
        });
  }

  Future<void> _concludeActiveGame() async {
    if (_activeGame == null) return;

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
                    'CONCLUDE CURRENT MATCH',
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
              Text(
                'Round ${_activeGame!.currentRound} • Select outcome to finalize and save to match archive:',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _buildWinnerSelectionCard(sheetCtx, 'Town Victory', 'town', AppColors.townGlow, Icons.security_rounded),
              _buildWinnerSelectionCard(sheetCtx, 'Mafia Syndicate Victory', 'mafia', AppColors.mafiaGlow, Icons.local_fire_department_rounded),
              _buildWinnerSelectionCard(sheetCtx, 'Draw / Stalemate', 'draw', AppColors.textPrimary, Icons.balance_rounded),
              _buildWinnerSelectionCard(sheetCtx, 'Archive Inconclusive Match', 'archived', AppColors.textMuted, Icons.inventory_2_rounded),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWinnerSelectionCard(
    BuildContext sheetCtx,
    String title,
    String teamKey,
    Color color,
    IconData icon,
  ) {
    return GlowCard(
      margin: const EdgeInsets.symmetric(vertical: 4),
      glowColor: color,
      onTap: () async {
        Navigator.of(sheetCtx).pop();
        if (_activeGame == null) return;

        final gameRepo = getIt<GameRepository>();
        final concluded = _activeGame!.copyWith(
          status: GameStatus.finished,
          endedAt: DateTime.now(),
          winnerTeam: teamKey,
        );
        await gameRepo.updateGame(concluded);
        await _checkActiveGame();
        if (mounted) {
          context.read<HistoryCubit>().loadHistory();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Match saved to match archive!')),
          );
        }
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

  void _startNewGameFlow() async {
    if (_activeGame != null) {
      final discard = await ConfirmDialog.show(
        context: context,
        title: 'Unfinished Game in Progress',
        message:
            'You have an unfinished game at Round ${_activeGame!.currentRound}. Starting a new game will archive the current match.',
        confirmText: 'START NEW GAME',
        confirmColor: AppColors.mafia,
        icon: Icons.warning_amber_rounded,
      );
      if (!discard) return;

      final gameRepo = getIt<GameRepository>();
      await gameRepo.updateGame(_activeGame!.copyWith(
        status: GameStatus.finished,
        endedAt: DateTime.now(),
        winnerTeam: _activeGame!.winnerTeam ?? 'Archived',
      ));
      if (mounted) {
        context.read<HistoryCubit>().loadHistory();
      }
    }

    if (!mounted) return;

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => GameSetupCubit(
                playerRepository: getIt<PlayerRepository>(),
                roleRepository: getIt<RoleRepository>(),
                settingsRepository: getIt<SettingsRepository>(),
              )..init(),
              child: const SelectPlayersScreen(),
            ),
          ),
        )
        .then((_) {
          _checkActiveGame();
          if (mounted) {
            context.read<HistoryCubit>().loadHistory();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildPlayTab(),
          const RosterScreen(),
          const HistoryScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) _checkActiveGame();
          if (index == 2) context.read<HistoryCubit>().loadHistory();
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_filled_rounded),
            label: 'Play',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Players',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
        ],
      ),
    );
  }

  Widget _buildPlayTab() {
    return AtmosphericBackground(
      mood: AtmosphereMood.noir,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('MAFIA PRO'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Game Rules & Settings',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => SettingsCubit(getIt<SettingsRepository>())..loadSettings(),
                      child: const SettingsScreen(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // Hero Title & Atmosphere
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF221115),
                    Color(0xFF141824),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: AppColors.mafiaDark, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mafia.withValues(alpha: 0.18),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.mafia.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.mafiaGlow.withValues(alpha: 0.4)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.shield_rounded, color: AppColors.mafiaGlow, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'OFFLINE MODERATOR SUITE',
                                    style: TextStyle(
                                      color: AppColors.mafiaGlow,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'RULE THE UNDERWORLD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Moderate seamless party games with secret role reveals, silent night actions, and automated win detection.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const AppLottie(
                    assetName: 'detective_shield',
                    width: 68,
                    height: 68,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Resume Card (if active game exists)
            if (_activeGame != null && _activeGamePlayers != null) ...[
              GlowCard(
                glowColor: AppColors.dayAccent,
                padding: const EdgeInsets.all(18),
                onTap: _resumeActiveGame,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.dayAccent.withValues(alpha: 0.2),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.dayAccent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'GAME IN PROGRESS',
                                style: TextStyle(
                                  color: AppColors.dayAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                'Round ${_activeGame!.currentRound} • ${_activeGame!.currentPhase.value.toUpperCase()} PHASE',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBorder,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_activeGamePlayers!.where((p) => p.isAlive).length} Alive',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.dayAccent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              minimumSize: const Size(0, 44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _resumeActiveGame,
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'RESUME',
                                maxLines: 1,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.dayAccent,
                              side: const BorderSide(color: AppColors.dayAccent, width: 1.2),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              minimumSize: const Size(0, 44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _concludeActiveGame,
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'CONCLUDE',
                                maxLines: 1,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Hero Start New Game Button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mafia.withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  backgroundColor: AppColors.mafia,
                ),
                onPressed: _startNewGameFlow,
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline_rounded, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'START NEW GAME',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Feature Highlights Grid
            const Text(
              'GAME ESSENTIALS',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: GlowCard(
                    padding: const EdgeInsets.all(16),
                    onTap: () => setState(() => _currentIndex = 1), // go to Roster
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.groups_rounded, color: AppColors.townGlow, size: 26),
                        SizedBox(height: 10),
                        Text(
                          'Saved Roster',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage crew, avatars & stats',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlowCard(
                    padding: const EdgeInsets.all(16),
                    onTap: () {
                      setState(() => _currentIndex = 2);
                      context.read<HistoryCubit>().loadHistory();
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.history_edu_rounded, color: AppColors.gold, size: 26),
                        SizedBox(height: 10),
                        Text(
                          'Match Archive',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Browse past game logs',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
