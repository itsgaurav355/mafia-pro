import 'package:flutter/material.dart';

class AppColors {
  // Deep underworld / noir backgrounds
  static const Color background = Color(0xFF090B10);
  static const Color surface = Color(0xFF121620);
  static const Color surfaceElevated = Color(0xFF1A202E);
  static const Color surfaceBorder = Color(0xFF263044);
  static const Color surfaceBorderLight = Color(0xFF3B4863);

  // Teams & Allegiances
  // Mafia / Danger / Kills
  static const Color mafia = Color(0xFFE53935);
  static const Color mafiaDark = Color(0xFF8A1C14);
  static const Color mafiaGlow = Color(0xFFFF5252);

  // Town / Law & Order
  static const Color town = Color(0xFF388AF6);
  static const Color townDark = Color(0xFF153C70);
  static const Color townGlow = Color(0xFF64B5F6);

  // Neutral / Rogues
  static const Color neutral = Color(0xFFFFB300);
  static const Color neutralDark = Color(0xFF7A5600);
  static const Color neutralGlow = Color(0xFFFFD54F);

  // Specific Role Signature Colors
  static const Color don = Color(0xFFD32F2F);
  static const Color doctor = Color(0xFF00E676);
  static const Color commissioner = Color(0xFF00B0FF);
  static const Color vigilante = Color(0xFFFF6D00);
  static const Color escort = Color(0xFFE040FB);
  static const Color bodyguard = Color(0xFF7C4DFF);
  static const Color maniac = Color(0xFFFF1744);
  static const Color jester = Color(0xFFFFAB00);
  static const Color sidekick = Color(0xFF40C4FF);
  static const Color civilian = Color(0xFF90A4AE);

  // Day & Night Accents
  static const Color nightSky = Color(0xFF0D1322);
  static const Color nightAccent = Color(0xFF5C6BC0);
  static const Color daySky = Color(0xFF241C10);
  static const Color dayAccent = Color(0xFFFFB74D);

  // Status & Utility
  static const Color textPrimary = Color(0xFFF0F4F8);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color gold = Color(0xFFFFD700);

  // Gradients
  static const LinearGradient mafiaGradient = LinearGradient(
    colors: [Color(0xFFE53935), Color(0xFF8A1C14)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient townGradient = LinearGradient(
    colors: [Color(0xFF388AF6), Color(0xFF153C70)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neutralGradient = LinearGradient(
    colors: [Color(0xFFFFB300), Color(0xFF7A5600)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    colors: [Color(0x33263044), Color(0x11121620)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient noirBannerGradient = LinearGradient(
    colors: [Color(0xEE121620), Color(0xBB090B10)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const List<Color> playerAvatarColors = [
    Color(0xFFE53935), // Crimson
    Color(0xFF1E88E5), // Cobalt
    Color(0xFF43A047), // Jade
    Color(0xFFFB8C00), // Amber
    Color(0xFF8E24AA), // Amethyst
    Color(0xFF00ACC1), // Cyan
    Color(0xFFD81B60), // Ruby
    Color(0xFF3949AB), // Indigo
    Color(0xFF00897B), // Teal
    Color(0xFF7CB342), // Lime
    Color(0xFFF4511E), // Rust
    Color(0xFF5E35B1), // Deep Violet
  ];
}
