import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class PlayerAvatar extends StatelessWidget {
  final String name;
  final int colorValue;
  final double radius;
  final bool isAlive;
  final bool showAliveStatus;
  final String? roleKey;

  const PlayerAvatar({
    super.key,
    required this.name,
    required this.colorValue,
    this.radius = 24,
    this.isAlive = true,
    this.showAliveStatus = false,
    this.roleKey,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Color(colorValue);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isAlive
                  ? [baseColor.withValues(alpha: 0.9), baseColor.withValues(alpha: 0.5)]
                  : [Colors.grey.shade800, Colors.grey.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isAlive ? baseColor.withValues(alpha: 0.8) : Colors.red.shade900.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: isAlive
                ? [
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              _initials,
              style: TextStyle(
                color: isAlive ? Colors.white : Colors.white38,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.75,
              ),
            ),
          ),
        ),

        // Eliminated Skull / Cross badge
        if (showAliveStatus && !isAlive)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.mafiaDark,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
      ],
    );
  }
}
