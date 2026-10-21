import '../entities/game_settings.dart';

abstract class SettingsRepository {
  Future<GameSettings> getSettings();
  Future<void> saveSettings(GameSettings settings);
  Future<bool> hasSeenOnboarding();
  Future<void> setHasSeenOnboarding(bool seen);
  Future<String> exportDatabaseJson();
  Future<bool> importDatabaseJson(String jsonString);
}
