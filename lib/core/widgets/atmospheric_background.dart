import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum AtmosphereMood {
  noir,
  night,
  crimson,
  day,
}

class AtmosphericBackground extends StatelessWidget {
  final Widget child;
  final AtmosphereMood mood;

  const AtmosphericBackground({
    super.key,
    required this.child,
    this.mood = AtmosphereMood.noir,
  });

  @override
  Widget build(BuildContext context) {
    Color orbColor1;
    Color orbColor2;
    Alignment orb1Align;
    Alignment orb2Align;

    switch (mood) {
      case AtmosphereMood.night:
        orbColor1 = const Color(0xFF1E3A8A).withValues(alpha: 0.22);
        orbColor2 = const Color(0xFF4C1D95).withValues(alpha: 0.18);
        orb1Align = const Alignment(-0.8, -0.6);
        orb2Align = const Alignment(0.8, 0.7);
        break;
      case AtmosphereMood.crimson:
        orbColor1 = const Color(0xFF991B1B).withValues(alpha: 0.25);
        orbColor2 = const Color(0xFF450A0A).withValues(alpha: 0.3);
        orb1Align = const Alignment(0.7, -0.5);
        orb2Align = const Alignment(-0.6, 0.8);
        break;
      case AtmosphereMood.day:
        orbColor1 = const Color(0xFF92400E).withValues(alpha: 0.18);
        orbColor2 = const Color(0xFF78350F).withValues(alpha: 0.12);
        orb1Align = const Alignment(0.0, -0.8);
        orb2Align = const Alignment(0.5, 0.6);
        break;
      case AtmosphereMood.noir:
        orbColor1 = const Color(0xFF1E293B).withValues(alpha: 0.25);
        orbColor2 = const Color(0xFF0F172A).withValues(alpha: 0.3);
        orb1Align = const Alignment(-0.7, -0.4);
        orb2Align = const Alignment(0.8, 0.5);
        break;
    }

    return Stack(
      children: [
        // Base dark void
        Container(color: AppColors.background),

        // Ambient Orb 1
        Positioned.fill(
          child: Align(
            alignment: orb1Align,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [orbColor1, Colors.transparent],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Ambient Orb 2
        Positioned.fill(
          child: Align(
            alignment: orb2Align,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [orbColor2, Colors.transparent],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Subtle dark vignette overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),
        ),

        // Main content
        child,
      ],
    );
  }
}
