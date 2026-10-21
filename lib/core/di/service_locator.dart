import 'package:get_it/get_it.dart';
import '../../data/repositories/sqlite_game_repository.dart';
import '../../data/repositories/sqlite_player_repository.dart';
import '../../data/repositories/sqlite_role_repository.dart';
import '../../data/repositories/sqlite_settings_repository.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/repositories/player_repository.dart';
import '../../domain/repositories/role_repository.dart';
import '../../domain/repositories/settings_repository.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Repositories
  getIt.registerLazySingleton<PlayerRepository>(() => SqlitePlayerRepository());
  getIt.registerLazySingleton<RoleRepository>(() => SqliteRoleRepository());
  getIt.registerLazySingleton<GameRepository>(() => SqliteGameRepository());
  getIt.registerLazySingleton<SettingsRepository>(() => SqliteSettingsRepository());
}
