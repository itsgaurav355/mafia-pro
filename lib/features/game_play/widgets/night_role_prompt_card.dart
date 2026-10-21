import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_lottie.dart';
import '../../../core/widgets/glow_card.dart';
import '../../../core/widgets/player_avatar.dart';
import '../../../core/widgets/role_badge.dart';
import '../../../domain/entities/game_player.dart';
import '../../../domain/roles/role_behavior.dart';

class NightRolePromptCard extends StatefulWidget {
  final RoleBehavior role;
  final List<GamePlayer> livingPlayers;
  final Function(int? targetPlayerId) onTargetSelected;
  final VoidCallback onUndo;
  final bool canUndo;
  final bool vigilanteHasFired;
  final int? lastNightDoctorTargetId;
  final int? lastNightEscortTargetId;
  final bool consecutiveSaveRule;
  final bool doctorSelfSave;

  const NightRolePromptCard({
    super.key,
    required this.role,
    required this.livingPlayers,
    required this.onTargetSelected,
    required this.onUndo,
    required this.canUndo,
    this.vigilanteHasFired = false,
    this.lastNightDoctorTargetId,
    this.lastNightEscortTargetId,
    this.consecutiveSaveRule = true,
    this.doctorSelfSave = true,
  });

  @override
  State<NightRolePromptCard> createState() => _NightRolePromptCardState();
}

class _NightRolePromptCardState extends State<NightRolePromptCard> {
  int? _selectedPlayerId;

  Color get _roleAccentColor {
    switch (widget.role.key) {
      case 'don':
      case 'mafia':
        return AppColors.mafiaGlow;
      case 'doctor':
        return AppColors.doctor;
      case 'commissioner':
        return AppColors.commissioner;
      case 'vigilante':
        return AppColors.vigilante;
      case 'bodyguard':
        return AppColors.bodyguard;
      case 'escort':
        return AppColors.escort;
      case 'maniac':
        return AppColors.maniac;
      default:
        return AppColors.neutralGlow;
    }
  }

  void _showCommissionerResult(GamePlayer target) {
    final isMafia = target.roleKey == 'mafia'; // Don registers innocent
    final resultText = isMafia ? 'MAFIA SYNDICATE' : 'INNOCENT';
    final resultColor = isMafia ? AppColors.mafiaGlow : AppColors.success;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: resultColor, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: resultColor.withValues(alpha: 0.15),
                ),
                child: Icon(
                  isMafia ? Icons.warning_rounded : Icons.verified_user_rounded,
                  color: resultColor,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'COMMISSIONER REPORT',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                target.displayNameSnapshot,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: resultColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  resultText,
                  style: TextStyle(
                    color: resultColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Show this secretly to the Commissioner, then tap Continue.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: resultColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    widget.onTargetSelected(target.id);
                  },
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'CONFIRM & CONTINUE',
                      style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = _roleAccentColor;

    // Check if vigilante already used single bullet
    final isVigilanteExhausted =
        widget.role.key == 'vigilante' && widget.vigilanteHasFired;

    return Column(
      children: [
        // Role Header Banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  RoleBadge(
                    roleName: widget.role.name,
                    team: widget.role.team.value,
                    roleKey: widget.role.key,
                  ),
                  const Spacer(),
                  const AppLottie(
                    assetName: 'night_moon',
                    width: 36,
                    height: 36,
                  ),
                  if (widget.canUndo) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.undo_rounded, size: 20),
                      tooltip: 'Previous Role',
                      onPressed: widget.onUndo,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.role.moderatorPrompt,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        // Vigilante exhausted banner
        if (isVigilanteExhausted)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.block_rounded, color: AppColors.textMuted, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Vigilante has already fired their single bullet this game. Skip this call.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Target Picker Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SELECT LIVING TARGET',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              TextButton(
                onPressed: () => widget.onTargetSelected(null),
                child: const Text('NO TARGET / PASS'),
              ),
            ],
          ),
        ),

        // Target List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.livingPlayers.length,
            itemBuilder: (context, index) {
              final player = widget.livingPlayers[index];
              final isSelected = _selectedPlayerId == player.id;

              // Check consecutive restrictions
              bool isRestricted = false;
              String? restrictionNotice;
              if (widget.role.key == 'doctor' &&
                  widget.consecutiveSaveRule &&
                  player.id == widget.lastNightDoctorTargetId) {
                isRestricted = true;
                restrictionNotice = 'Cannot save consecutively';
              } else if (widget.role.key == 'escort' &&
                  widget.consecutiveSaveRule &&
                  player.id == widget.lastNightEscortTargetId) {
                isRestricted = true;
                restrictionNotice = 'Cannot block consecutively';
              }

              return GlowCard(
                isSelected: isSelected,
                glowColor: accent,
                margin: const EdgeInsets.symmetric(vertical: 4),
                onTap: isRestricted
                    ? null
                    : () {
                        setState(() => _selectedPlayerId = player.id);
                        if (widget.role.key == 'commissioner') {
                          _showCommissionerResult(player);
                        } else {
                          widget.onTargetSelected(player.id);
                        }
                      },
                child: Row(
                  children: [
                    PlayerAvatar(
                      name: player.displayNameSnapshot,
                      colorValue: player.avatarColor ?? AppColors.playerAvatarColors[0].toARGB32(),
                      radius: 18,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.displayNameSnapshot,
                            style: TextStyle(
                              color: isRestricted ? AppColors.textMuted : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (restrictionNotice != null)
                            Text(
                              restrictionNotice,
                              style: const TextStyle(
                                color: AppColors.warning,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, color: accent, size: 22),
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
