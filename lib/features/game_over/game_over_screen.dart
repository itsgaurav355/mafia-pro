import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_lottie.dart';
import '../../core/widgets/atmospheric_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/player_avatar.dart';
import '../../core/widgets/role_badge.dart';
import '../../domain/engine/win_condition_checker.dart';
import '../../domain/entities/game.dart';
import '../../domain/entities/game_event.dart';
import '../../domain/entities/game_player.dart';

class GameOverScreen extends StatelessWidget {
  final Game game;
  final List<GamePlayer> allPlayers;
  final WinResult winResult;
  final List<GameEvent> eventHistory;

  const GameOverScreen({
    super.key,
    required this.game,
    required this.allPlayers,
    required this.winResult,
    required this.eventHistory,
  });

  Color get _victoryColor {
    switch (winResult) {
      case WinResult.townWin:
        return AppColors.townGlow;
      case WinResult.mafiaWin:
        return AppColors.mafiaGlow;
      case WinResult.jesterWin:
        return AppColors.jester;
      case WinResult.maniacWin:
        return AppColors.maniac;
      case WinResult.inProgress:
        return Colors.white;
    }
  }

  IconData get _victoryIcon {
    switch (winResult) {
      case WinResult.townWin:
        return Icons.security_rounded;
      case WinResult.mafiaWin:
        return Icons.local_fire_department_rounded;
      case WinResult.jesterWin:
        return Icons.theater_comedy_rounded;
      case WinResult.maniacWin:
        return Icons.flash_on_rounded;
      case WinResult.inProgress:
        return Icons.flag_rounded;
    }
  }

  void _shareGameReport(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln('🕵️‍♂️ MAFIA PRO — GAME SUMMARY');
    buffer.writeln('🏆 Winner: ${winResult.title}');
    buffer.writeln('📜 ${winResult.subtitle}');
    buffer.writeln('📅 Date: ${DateFormat.yMMMd().format(game.startedAt)}');
    buffer.writeln('⏱️ Rounds: ${game.currentRound}');
    buffer.writeln('👥 Total Players: ${allPlayers.length}');
    buffer.writeln('');
    buffer.writeln('--- PLAYER ROLES & FATES ---');
    for (final p in allPlayers) {
      final status = p.isAlive
          ? 'SURVIVED'
          : 'ELIMINATED (Round ${p.eliminatedRound ?? "?"} by ${p.eliminatedBy ?? "Unknown"})';
      buffer.writeln('• ${p.displayNameSnapshot}: ${p.roleName} [${p.roleTeam?.toUpperCase()}] — $status');
    }
    buffer.writeln('');
    buffer.writeln('Moderated offline with Mafia Pro.');

    SharePlus.instance.share(ShareParams(text: buffer.toString(), subject: 'Mafia Pro Game Result'));
  }

  @override
  Widget build(BuildContext context) {
    final color = _victoryColor;
    final livingCount = allPlayers.where((p) => p.isAlive).length;

    return AtmosphericBackground(
      mood: AtmosphereMood.crimson,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('GAME OVER'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              tooltip: 'Share Game Summary',
              onPressed: () => _shareGameReport(context),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
          ),
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_rounded, size: 20),
                SizedBox(width: 8),
                Text('RETURN TO HOME'),
              ],
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // Victory Crest
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.15),
                      border: Border.all(color: color, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  AppLottie(
                    assetName: 'trophy_victory',
                    width: 140,
                    height: 140,
                    fallback: Icon(_victoryIcon, color: color, size: 48),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              winResult.title.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              winResult.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            // Quick Stats Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${game.currentRound}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'ROUNDS',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$livingCount / ${allPlayers.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'SURVIVORS',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // All Player Assignments Breakdown
            const Text(
              'FINAL ROSTER & SECRET IDENTITIES',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),

            ...allPlayers.map((gp) {
              return GlowCard(
                glowColor: gp.isAlive ? color : Colors.transparent,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    PlayerAvatar(
                      name: gp.displayNameSnapshot,
                      colorValue: gp.avatarColor ?? AppColors.playerAvatarColors[0].toARGB32(),
                      isAlive: gp.isAlive,
                      showAliveStatus: true,
                      radius: 20,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gp.displayNameSnapshot,
                            style: TextStyle(
                              color: gp.isAlive ? Colors.white : AppColors.textMuted,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            gp.isAlive
                                ? 'Survived until end'
                                : 'Eliminated (Round ${gp.eliminatedRound ?? "?"})',
                            style: TextStyle(
                              color: gp.isAlive ? AppColors.success : AppColors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

            const SizedBox(height: 24),

            // Share Card Action
            OutlinedButton.icon(
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'SHARE SCORECARD TO CHAT',
                  maxLines: 1,
                ),
              ),
              onPressed: () => _shareGameReport(context),
            ),
          ],
        ),
      ),
    );
  }
}
