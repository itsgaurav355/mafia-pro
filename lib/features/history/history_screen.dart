import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import '../../core/widgets/atmospheric_background.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/player_avatar.dart';
import '../../core/widgets/role_badge.dart';
import '../../domain/entities/game.dart';
import '../../domain/entities/game_player.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../game_play/game_play_bloc.dart';
import '../game_play/game_play_screen.dart';
import 'history_cubit.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Game? _activeGame;
  List<GamePlayer>? _activeGamePlayers;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final gameRepo = getIt<GameRepository>();
    final active = await gameRepo.getActiveGame();
    List<GamePlayer>? players;
    if (active != null && active.id != null) {
      players = await gameRepo.getGamePlayers(active.id!);
    }

    if (mounted) {
      setState(() {
        _activeGame = active;
        _activeGamePlayers = players;
      });
      await context.read<HistoryCubit>().loadHistory();
    }
  }

  Color _getWinnerColor(String? winnerTeam) {
    switch (winnerTeam?.toLowerCase()) {
      case 'town':
        return AppColors.townGlow;
      case 'mafia':
        return AppColors.mafiaGlow;
      case 'jester':
        return AppColors.jester;
      case 'maniac':
        return AppColors.maniac;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getWinnerTitle(String? winnerTeam) {
    switch (winnerTeam?.toLowerCase()) {
      case 'town':
        return 'TOWN VICTORY';
      case 'mafia':
        return 'MAFIA VICTORY';
      case 'jester':
        return 'JESTER VICTORY';
      case 'maniac':
        return 'MANIAC VICTORY';
      case 'draw':
        return 'DRAW (STALEMATE)';
      case 'archived':
      case 'abandoned':
        return 'CONCLUDED MATCH';
      default:
        return '${(winnerTeam ?? "MATCH").toUpperCase()} VICTORY';
    }
  }

  IconData _getWinnerIcon(String? winnerTeam) {
    switch (winnerTeam?.toLowerCase()) {
      case 'town':
        return Icons.security_rounded;
      case 'mafia':
        return Icons.local_fire_department_rounded;
      case 'jester':
        return Icons.theater_comedy_rounded;
      case 'maniac':
        return Icons.flash_on_rounded;
      case 'draw':
        return Icons.balance_rounded;
      case 'archived':
      case 'abandoned':
        return Icons.inventory_2_rounded;
      default:
        return Icons.emoji_events_rounded;
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
        .then((_) => _refresh());
  }

  void _showConcludeActiveGameModal() {
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
                    'CONCLUDE & ARCHIVE MATCH',
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
                'Round ${_activeGame!.currentRound} • Choose outcome to archive this game:',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _buildWinnerChoiceCard(sheetCtx, 'Town Victory', 'town', AppColors.townGlow, Icons.security_rounded),
              _buildWinnerChoiceCard(sheetCtx, 'Mafia Syndicate Victory', 'mafia', AppColors.mafiaGlow, Icons.local_fire_department_rounded),
              _buildWinnerChoiceCard(sheetCtx, 'Draw / Stalemate', 'draw', AppColors.textPrimary, Icons.balance_rounded),
              _buildWinnerChoiceCard(sheetCtx, 'Archive Inconclusive Match', 'archived', AppColors.textMuted, Icons.inventory_2_rounded),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWinnerChoiceCard(
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
        await _refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Match saved to history archive!')),
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

  void _showGameDetails(BuildContext context, Game game) async {
    final gameRepo = getIt<GameRepository>();
    final players = await gameRepo.getGamePlayers(game.id!);
    final events = await gameRepo.getGameEvents(game.id!);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final winnerColor = _getWinnerColor(game.winnerTeam);
        final winnerTitle = _getWinnerTitle(game.winnerTeam);

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: controller,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            winnerTitle,
                            style: TextStyle(
                              color: winnerColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            DateFormat.yMMMd().add_jm().format(game.startedAt),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                        tooltip: 'Share Game Log',
                        onPressed: () {
                          final buffer = StringBuffer();
                          buffer.writeln('🕵️‍♂️ MAFIA PRO ARCHIVE');
                          buffer.writeln('🏆 Result: $winnerTitle');
                          buffer.writeln('📅 Date: ${DateFormat.yMMMd().format(game.startedAt)}');
                          buffer.writeln('⏱️ Rounds: ${game.currentRound}');
                          buffer.writeln('');
                          buffer.writeln('--- PARTICIPANTS ---');
                          for (final p in players) {
                            buffer.writeln('• ${p.displayNameSnapshot}: ${p.roleName} (${p.roleTeam})');
                          }
                          SharePlus.instance.share(ShareParams(text: buffer.toString(), subject: 'Mafia Pro Archive'));
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text(
                    'PLAYERS & ROLES',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...players.map((p) => GlowCard(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            PlayerAvatar(
                              name: p.displayNameSnapshot,
                              colorValue: p.avatarColor ?? AppColors.playerAvatarColors[0].toARGB32(),
                              isAlive: p.isAlive,
                              showAliveStatus: true,
                              radius: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                p.displayNameSnapshot,
                                style: TextStyle(
                                  color: p.isAlive ? Colors.white : AppColors.textMuted,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            RoleBadge(
                              roleName: p.roleName ?? 'Unknown',
                              team: p.roleTeam ?? 'town',
                              roleKey: p.roleKey,
                              compact: true,
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 20),
                  if (events.isNotEmpty) ...[
                    const Text(
                      'EVENT LOG',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...events.map((e) => Container(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceBorder,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'R${e.round} ${e.phase.toUpperCase()}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  e.result ?? e.eventType,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AtmosphericBackground(
      mood: AtmosphereMood.noir,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('MATCH HISTORY'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh History',
              onPressed: _refresh,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.mafiaGlow,
          backgroundColor: AppColors.surfaceElevated,
          child: BlocBuilder<HistoryCubit, HistoryState>(
            builder: (context, state) {
              if (state is HistoryLoading && _activeGame == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is HistoryError && _activeGame == null) {
                return Center(
                  child: Text(state.message, style: const TextStyle(color: AppColors.error)),
                );
              }

              final games = state is HistoryLoaded ? state.games : <Game>[];

              if (games.isEmpty && _activeGame == null) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: const EmptyState(
                        lottieAsset: 'empty_box',
                        icon: Icons.history_toggle_off_rounded,
                        title: 'No Completed Games',
                        message:
                            'Finish a game session to browse full round-by-round chronicles, player roles, and event logs. Pull down to refresh anytime.',
                      ),
                    ),
                  ],
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: games.length + (_activeGame != null ? 1 : 0),
                itemBuilder: (context, index) {
                  // Active game banner card at top
                  if (_activeGame != null && index == 0) {
                    final aliveCount =
                        _activeGamePlayers?.where((p) => p.isAlive).length ?? 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: GlowCard(
                        glowColor: AppColors.dayAccent,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.dayAccent,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'ACTIVE SESSION IN PROGRESS',
                                  style: TextStyle(
                                    color: AppColors.dayAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Round ${_activeGame!.currentRound} • ${_activeGame!.currentPhase.value.toUpperCase()} PHASE • $aliveCount Players Alive',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
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
                                    onPressed: _showConcludeActiveGameModal,
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
                    );
                  }

                  final gameIndex = _activeGame != null ? index - 1 : index;
                  final game = games[gameIndex];
                  final winnerColor = _getWinnerColor(game.winnerTeam);
                  final winnerTitle = _getWinnerTitle(game.winnerTeam);
                  final winnerIcon = _getWinnerIcon(game.winnerTeam);
                  final dateFormatted = DateFormat.yMMMd().format(game.startedAt);

                  return GlowCard(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    glowColor: winnerColor,
                    onTap: () => _showGameDetails(context, game),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: winnerColor.withValues(alpha: 0.15),
                            border: Border.all(color: winnerColor.withValues(alpha: 0.6), width: 1.5),
                          ),
                          child: Icon(
                            winnerIcon,
                            color: winnerColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                winnerTitle,
                                style: TextStyle(
                                  color: winnerColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$dateFormatted • ${game.currentRound} Rounds',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMuted,
                          size: 22,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
