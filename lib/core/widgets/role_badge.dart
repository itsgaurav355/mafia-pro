import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class RoleBadge extends StatelessWidget {
  final String roleName;
  final String team;
  final String? roleKey;
  final bool compact;

  const RoleBadge({
    super.key,
    required this.roleName,
    required this.team,
    this.roleKey,
    this.compact = false,
  });

  Color get _teamColor {
    switch (team.toLowerCase()) {
      case 'mafia':
        return AppColors.mafia;
      case 'town':
        return AppColors.town;
      case 'neutral':
      default:
        return AppColors.neutral;
    }
  }

  IconData get _roleIcon {
    switch (roleKey?.toLowerCase()) {
      case 'don':
        return Icons.military_tech_rounded;
      case 'mafia':
        return Icons.local_fire_department_rounded;
      case 'commissioner':
        return Icons.search_rounded;
      case 'doctor':
        return Icons.medical_services_rounded;
      case 'vigilante':
        return Icons.gps_fixed_rounded;
      case 'bodyguard':
        return Icons.shield_rounded;
      case 'escort':
        return Icons.favorite_rounded;
      case 'maniac':
        return Icons.flash_on_rounded;
      case 'jester':
        return Icons.theater_comedy_rounded;
      case 'detective_sidekick':
        return Icons.visibility_rounded;
      case 'civilian':
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _teamColor;

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_roleIcon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(
              roleName,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 8,
            spreadRadius: 0,
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_roleIcon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            roleName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              team.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
