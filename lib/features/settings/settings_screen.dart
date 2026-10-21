import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/atmospheric_background.dart';
import '../../core/widgets/glow_card.dart';
import 'settings_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AtmosphericBackground(
      mood: AtmosphereMood.noir,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('GAME RULES & SETTINGS'),
        ),
        body: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            if (state is SettingsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SettingsLoaded) {
              final settings = state.settings;
              final cubit = context.read<SettingsCubit>();

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  const Text(
                    'MODERATOR GAME RULES',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Reveal Role on Death
                  GlowCard(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Reveal Role on Death',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text(
                        'Town publicly learns the secret identity and team allegiance of eliminated players.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      activeThumbColor: AppColors.mafiaGlow,
                      value: settings.revealRoleOnDeath,
                      onChanged: (val) => cubit.updateSettings(
                        settings.copyWith(revealRoleOnDeath: val),
                      ),
                    ),
                  ),

                  // Doctor Self-Save
                  GlowCard(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Doctor Self-Save',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text(
                        'Allows the Doctor to protect themselves during the night phase.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      activeThumbColor: AppColors.doctor,
                      value: settings.doctorSelfSave,
                      onChanged: (val) => cubit.updateSettings(
                        settings.copyWith(doctorSelfSave: val),
                      ),
                    ),
                  ),

                  // Consecutive Save Rule
                  GlowCard(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Consecutive Target Restriction',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text(
                        'Prevents the Doctor and Escort from targeting the exact same player two nights in a row.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      activeThumbColor: AppColors.townGlow,
                      value: settings.consecutiveSaveRule,
                      onChanged: (val) => cubit.updateSettings(
                        settings.copyWith(consecutiveSaveRule: val),
                      ),
                    ),
                  ),

                  // Mafia Teammates Awareness
                  GlowCard(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Mafia Teammates Awareness',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text(
                        'Mafia members see who their syndicate partners are during secret role reveal.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      activeThumbColor: AppColors.mafiaGlow,
                      value: settings.mafiaSeeEachOther,
                      onChanged: (val) => cubit.updateSettings(
                        settings.copyWith(mafiaSeeEachOther: val),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Discussion Timer Duration
                  GlowCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Default Discussion Timer',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${settings.discussionTimerSeconds}s',
                              style: const TextStyle(
                                color: AppColors.dayAccent,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Starting countdown time for daytime accusations and town debate.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: settings.discussionTimerSeconds.toDouble(),
                          min: 30,
                          max: 300,
                          divisions: 9,
                          activeColor: AppColors.dayAccent,
                          inactiveColor: AppColors.surfaceBorder,
                          label: '${settings.discussionTimerSeconds}s',
                          onChanged: (val) => cubit.updateSettings(
                            settings.copyWith(discussionTimerSeconds: val.toInt()),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'OFFLINE DATA & BACKUP',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Export DB Backup
                  GlowCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.cloud_download_outlined, color: AppColors.townGlow),
                      title: const Text(
                        'Export Database Backup',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text(
                        'Save or share full offline player roster and game history as a JSON backup.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () async {
                        final json = await cubit.exportDatabase();
                        SharePlus.instance.share(ShareParams(text: json, subject: 'Mafia Pro Database Backup'));
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Offline Privacy Seal
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.shield_rounded, color: AppColors.success, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '100% Offline & Private. No cloud tracking, accounts, or internet permissions required.',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
