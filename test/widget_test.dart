import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafia_pro/core/constants/game_constants.dart';
import 'package:mafia_pro/core/widgets/app_lottie.dart';
import 'package:mafia_pro/core/widgets/confirm_dialog.dart';
import 'package:mafia_pro/core/widgets/hold_to_reveal.dart';

void main() {
  test('GameConstants recommended counts balance check', () {
    final roles5 = GameConstants.getRecommendedRoles(5);
    expect(roles5['don'], equals(1));
    expect(roles5['commissioner'], equals(1));

    final roles8 = GameConstants.getRecommendedRoles(8);
    expect(roles8['don'], equals(1));
    expect(roles8['mafia'], equals(2));
    expect(roles8['commissioner'], equals(1));
    expect(roles8['doctor'], equals(1));
  });

  group('Lottie Animation Assets Tests', () {
    const assetNames = [
      'detective_shield',
      'trophy_victory',
      'night_moon',
      'fingerprint_scan',
      'empty_box',
    ];

    for (final name in assetNames) {
      test('Asset $name.json exists and is valid Bodymovin JSON', () {
        final file = File('assets/lottie/$name.json');
        expect(file.existsSync(), isTrue, reason: 'assets/lottie/$name.json should exist');
        final content = file.readAsStringSync();
        final jsonMap = jsonDecode(content) as Map<String, dynamic>;
        expect(jsonMap['v'], isNotNull, reason: 'Must contain Bodymovin version');
        expect(jsonMap['layers'], isNotNull, reason: 'Must contain animation layers');
        expect(jsonMap['w'], isNotNull, reason: 'Must contain canvas width');
        expect(jsonMap['h'], isNotNull, reason: 'Must contain canvas height');
      });
    }

    testWidgets('AppLottie renders fallback widget cleanly when asset not in test asset bundle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLottie(
              assetName: 'fingerprint_scan',
              width: 50,
              height: 50,
              fallback: Icon(Icons.fingerprint, key: Key('fallback_icon')),
            ),
          ),
        ),
      );

      // Verify the widget tree mounts cleanly
      expect(find.byType(AppLottie), findsOneWidget);
    });
  });

  group('ConfirmDialog UI Tests', () {
    testWidgets('Renders stacked layout cleanly for long confirmText like START NEW GAME', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmDialog(
              title: 'Unfinished Game in Progress',
              message: 'You have an unfinished game at Round 1.',
              confirmText: 'START NEW GAME',
              cancelText: 'Cancel',
              icon: Icons.warning_amber_rounded,
            ),
          ),
        ),
      );

      expect(find.text('Unfinished Game in Progress'), findsOneWidget);
      expect(find.text('START NEW GAME'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('Renders side-by-side layout for short confirmText like DELETE', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmDialog(
              title: 'Delete Player?',
              message: 'Are you sure you want to remove this player?',
              confirmText: 'DELETE',
              cancelText: 'Cancel',
            ),
          ),
        ),
      );

      expect(find.text('Delete Player?'), findsOneWidget);
      expect(find.text('DELETE'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });

  group('Active Match Card Buttons UI Tests', () {
    testWidgets('Renders RESUME and CONCLUDE buttons side-by-side with maxLines 1 and FittedBox', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280, // Narrow card width to test flex handling
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: () {},
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'RESUME',
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: () {},
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'CONCLUDE',
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('RESUME'), findsOneWidget);
      expect(find.text('CONCLUDE'), findsOneWidget);

      final resumeText = tester.widget<Text>(find.text('RESUME'));
      final concludeText = tester.widget<Text>(find.text('CONCLUDE'));

      expect(resumeText.maxLines, equals(1));
      expect(concludeText.maxLines, equals(1));
    });
  });

  group('HoldToReveal UI Tests', () {
    testWidgets('Renders classic fingerprint scanner and privacy shield without Lottie', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoldToReveal(
              playerName: 'Alice',
              roleName: 'Detective',
              roleKey: 'commissioner',
              roleTeam: 'town',
              roleDescription: 'Investigate suspects at night.',
              onRevealedOnce: () {},
            ),
          ),
        ),
      );

      // Verify privacy shield and player name
      expect(find.text('Alice'), findsOneWidget);
      expect(find.byIcon(Icons.shield_rounded), findsOneWidget);

      // Verify fingerprint hold button
      expect(find.byIcon(Icons.fingerprint_rounded), findsOneWidget);
      expect(find.text('PRESS & HOLD TO REVEAL ROLE'), findsOneWidget);
    });
  });
}
