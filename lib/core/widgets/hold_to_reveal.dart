import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import 'role_badge.dart';

class HoldToReveal extends StatefulWidget {
  final String playerName;
  final String roleName;
  final String roleKey;
  final String roleTeam;
  final String roleDescription;
  final List<String> mafiaTeammates; // if mafia awareness is on
  final VoidCallback onRevealedOnce;

  const HoldToReveal({
    super.key,
    required this.playerName,
    required this.roleName,
    required this.roleKey,
    required this.roleTeam,
    required this.roleDescription,
    this.mafiaTeammates = const [],
    required this.onRevealedOnce,
  });

  @override
  State<HoldToReveal> createState() => _HoldToRevealState();
}

class _HoldToRevealState extends State<HoldToReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isRevealed = false;
  bool _hasEverRevealed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isRevealed = true;
          if (!_hasEverRevealed) {
            _hasEverRevealed = true;
            widget.onRevealedOnce();
          }
        });
        HapticFeedback.heavyImpact();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPressDown(TapDownDetails _) {
    _controller.forward();
  }

  void _onPressUp(TapUpDetails _) {
    _hide();
  }

  void _onPressCancel() {
    _hide();
  }

  void _hide() {
    if (_isRevealed) {
      HapticFeedback.selectionClick();
    }
    setState(() {
      _isRevealed = false;
    });
    _controller.reverse();
  }

  Color get _teamGlowColor {
    switch (widget.roleTeam.toLowerCase()) {
      case 'mafia':
        return AppColors.mafiaGlow;
      case 'town':
        return AppColors.townGlow;
      case 'neutral':
      default:
        return AppColors.neutralGlow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Role Revealed Card or Privacy Veil
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          child: _isRevealed ? _buildRevealedDossier() : _buildPrivacyShield(),
        ),

        const SizedBox(height: 36),

        // Hold To Reveal Button
        GestureDetector(
          onTapDown: _onPressDown,
          onTapUp: _onPressUp,
          onTapCancel: _onPressCancel,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Circular Progress Ring
                  SizedBox(
                    width: 104,
                    height: 104,
                    child: CircularProgressIndicator(
                      value: _controller.value,
                      strokeWidth: 4,
                      backgroundColor: AppColors.surfaceBorder,
                      valueColor: AlwaysStoppedAnimation<Color>(_teamGlowColor),
                    ),
                  ),

                  // Center Fingerprint Button
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isRevealed
                            ? [_teamGlowColor.withValues(alpha: 0.4), AppColors.surfaceElevated]
                            : [AppColors.surfaceElevated, AppColors.surface],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: _isRevealed ? _teamGlowColor : AppColors.surfaceBorderLight,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isRevealed ? _teamGlowColor : Colors.black).withValues(alpha: 0.3),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRevealed ? Icons.lock_open_rounded : Icons.fingerprint_rounded,
                      color: _isRevealed ? _teamGlowColor : AppColors.textPrimary,
                      size: 44,
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 16),
        Text(
          _isRevealed
              ? 'RELEASE TO HIDE YOUR ROLE'
              : 'PRESS & HOLD TO REVEAL ROLE',
          style: TextStyle(
            color: _isRevealed ? _teamGlowColor : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyShield() {
    return Container(
      key: const ValueKey('privacy_shield'),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 260),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceBorder.withValues(alpha: 0.5),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: AppColors.textSecondary,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.playerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep your screen tilted away from other players.\nHold the button below to inspect your secret assignment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealedDossier() {
    final glow = _teamGlowColor;

    return Container(
      key: const ValueKey('revealed_dossier'),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 260),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: glow, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.25),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Player identifier
          Text(
            widget.playerName.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          // Role Badge
          RoleBadge(
            roleName: widget.roleName,
            team: widget.roleTeam,
            roleKey: widget.roleKey,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            widget.roleDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.45,
            ),
          ),

          // Mafia Syndicate Aware List
          if (widget.mafiaTeammates.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.mafiaDark.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.mafia.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.people_alt_rounded, color: AppColors.mafiaGlow, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'SYNDICATE MEMBERS',
                        style: TextStyle(
                          color: AppColors.mafiaGlow,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.mafiaTeammates.join(', '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
