import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import '../../core/widgets/app_lottie.dart';
import '../../core/widgets/atmospheric_background.dart';
import '../../domain/repositories/settings_repository.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.theater_comedy_rounded,
      'lottie': 'detective_shield',
      'title': 'THE UNDERWORLD AWAITS',
      'subtitle': 'One phone. One moderator. Complete offline secrecy.',
      'description':
          'No paper slips. No internet connection needed. Mafia Pro gives the moderator full control to run physical party games smoothly and fairly.',
      'color': AppColors.mafiaGlow,
    },
    {
      'icon': Icons.fingerprint_rounded,
      'lottie': 'fingerprint_scan',
      'title': 'SECRET HOLD-TO-REVEAL',
      'subtitle': 'Private roles kept strictly confidential.',
      'description':
          'Players take turns holding their thumb on the screen to view their assigned role. The moment they lift their finger, the veil drops instantly.',
      'color': AppColors.neutralGlow,
    },
    {
      'icon': Icons.nights_stay_rounded,
      'lottie': 'night_moon',
      'title': 'GUIDED NIGHT CALLS',
      'subtitle': 'Zero leaks. Silent skips for fallen players.',
      'description':
          'The app guides you role-by-role through night actions. Dead roles are handled seamlessly so nobody in the room deduces who has died.',
      'color': AppColors.townGlow,
    },
    {
      'icon': Icons.balance_rounded,
      'lottie': 'trophy_victory',
      'title': 'PERFECT BALANCE',
      'subtitle': '11 customizable roles with smart auto-balance.',
      'description':
          'From Don and Doctor to Bodyguard, Escort, and Maniac. Use one-tap Auto Balance or tune role counts to match your exact group size.',
      'color': AppColors.doctor,
    },
  ];

  void _onNext() async {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await getIt<SettingsRepository>().setHasSeenOnboarding(true);
      widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AtmosphericBackground(
        mood: AtmosphereMood.crimson,
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () async {
                    await getIt<SettingsRepository>().setHasSeenOnboarding(true);
                    widget.onFinish();
                  },
                  child: const Text('SKIP'),
                ),
              ),

              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    final color = slide['color'] as Color;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 116,
                            height: 116,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withValues(alpha: 0.12),
                              border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.25),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: Center(
                              child: AppLottie(
                                assetName: slide['lottie'] as String,
                                width: 72,
                                height: 72,
                                fallback: Icon(
                                  slide['icon'] as IconData,
                                  size: 54,
                                  color: color,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),
                          Text(
                            slide['title'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            slide['subtitle'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: color,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slide['description'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Dots indicator & Next/Enter button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentPage == i
                                ? AppColors.mafiaGlow
                                : AppColors.surfaceBorderLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _onNext,
                      child: Text(
                        _currentPage == _slides.length - 1
                            ? 'ENTER THE UNDERWORLD'
                            : 'NEXT',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
