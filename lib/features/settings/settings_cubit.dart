import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/game_settings.dart';
import '../../domain/repositories/settings_repository.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final GameSettings settings;
  const SettingsLoaded(this.settings);

  @override
  List<Object?> get props => [settings];
}

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _settingsRepository;

  SettingsCubit(this._settingsRepository) : super(SettingsInitial());

  Future<void> loadSettings() async {
    emit(SettingsLoading());
    final settings = await _settingsRepository.getSettings();
    emit(SettingsLoaded(settings));
  }

  Future<void> updateSettings(GameSettings updated) async {
    await _settingsRepository.saveSettings(updated);
    emit(SettingsLoaded(updated));
  }

  Future<String> exportDatabase() async {
    return await _settingsRepository.exportDatabaseJson();
  }
}
