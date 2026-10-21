import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'domain/repositories/game_repository.dart';
import 'domain/repositories/player_repository.dart';
import 'domain/repositories/settings_repository.dart';
import 'features/history/history_cubit.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/roster/roster_cubit.dart';
import 'features/settings/settings_cubit.dart';

class MafiaProApp extends StatefulWidget {
  final bool initialHasSeenOnboarding;

  const MafiaProApp({
    super.key,
    required this.initialHasSeenOnboarding,
  });

  @override
  State<MafiaProApp> createState() => _MafiaProAppState();
}

class _MafiaProAppState extends State<MafiaProApp> {
  late bool _hasSeenOnboarding;

  @override
  void initState() {
    super.initState();
    _hasSeenOnboarding = widget.initialHasSeenOnboarding;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RosterCubit>(
          create: (_) => RosterCubit(getIt<PlayerRepository>())..loadPlayers(),
        ),
        BlocProvider<HistoryCubit>(
          create: (_) => HistoryCubit(getIt<GameRepository>())..loadHistory(),
        ),
        BlocProvider<SettingsCubit>(
          create: (_) => SettingsCubit(getIt<SettingsRepository>())..loadSettings(),
        ),
      ],
      child: MaterialApp(
        title: 'Mafia Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: _hasSeenOnboarding
            ? const HomeScreen()
            : OnboardingScreen(
                onFinish: () {
                  setState(() {
                    _hasSeenOnboarding = true;
                  });
                },
              ),
      ),
    );
  }
}
