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

  // Prevent device screen from falling asleep during live game sessions
  try {
    await WakelockPlus.enable();
  } catch (_) {
    // Graceful fallback on unsupported platforms
  }

  // Check if first launch onboarding is needed
  final settingsRepo = getIt<SettingsRepository>();
  final hasSeen = await settingsRepo.hasSeenOnboarding();

  runApp(MafiaProApp(initialHasSeenOnboarding: hasSeen));
}
