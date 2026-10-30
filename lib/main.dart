import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'app.dart';
import 'core/di/service_locator.dart';
import 'domain/repositories/settings_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI to immersive dark mode style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF121620),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize dependencies
  await setupServiceLocator();

  // Check if first launch onboarding is needed with safe fallback
  bool hasSeen = false;
  try {
    final settingsRepo = getIt<SettingsRepository>();
    hasSeen = await settingsRepo.hasSeenOnboarding().timeout(
      const Duration(seconds: 2),
      onTimeout: () => false,
    );
  } catch (e) {
    debugPrint('Safe onboarding initialization fallback: $e');
  }

  runApp(MafiaProApp(initialHasSeenOnboarding: hasSeen));

  // Enable screen wakelock smoothly after UI is rendered
  WidgetsBinding.instance.addPostFrameCallback((_) {
    try {
      WakelockPlus.enable();
    } catch (_) {
      // Graceful fallback on unsupported platforms
    }
  });
}
