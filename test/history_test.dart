import 'package:flutter_test/flutter_test.dart';
import 'package:mafia_pro/domain/engine/win_condition_checker.dart';
import 'package:mafia_pro/domain/entities/game.dart';
import 'package:mafia_pro/domain/entities/game_settings.dart';

void main() {
  group('History and Win Result Tests', () {
    test('GameStatus fromString handles archived correctly', () {
      expect(GameStatus.fromString('archived'), equals(GameStatus.finished));
      expect(GameStatus.fromString('finished'), equals(GameStatus.finished));
      expect(GameStatus.fromString('in_progress'), equals(GameStatus.inProgress));
      expect(GameStatus.fromString('reveal'), equals(GameStatus.reveal));
      expect(GameStatus.fromString('setup'), equals(GameStatus.setup));
    });

    test('WinResult.fromTeamKey maps teams correctly', () {
      expect(WinResult.fromTeamKey('town'), equals(WinResult.townWin));
      expect(WinResult.fromTeamKey('mafia'), equals(WinResult.mafiaWin));
      expect(WinResult.fromTeamKey('jester'), equals(WinResult.jesterWin));
      expect(WinResult.fromTeamKey('maniac'), equals(WinResult.maniacWin));
      expect(WinResult.fromTeamKey('draw'), equals(WinResult.inProgress));
      expect(WinResult.fromTeamKey('archived'), equals(WinResult.inProgress));
      expect(WinResult.fromTeamKey(null), equals(WinResult.inProgress));
    });

    test('Game serialization with finished and archived status', () {
      final now = DateTime.now();
      final finishedGame = Game(
        id: 42,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 20)),
        status: GameStatus.finished,
        currentRound: 3,
        currentPhase: GamePhase.day,
        winnerTeam: 'town',
        settings: const GameSettings(),
      );

      final map = finishedGame.toMap();
      expect(map['status'], equals('finished'));
      expect(map['winner_team'], equals('town'));

      final reconstructed = Game.fromMap(map);
      expect(reconstructed.status, equals(GameStatus.finished));
      expect(reconstructed.winnerTeam, equals('town'));
      expect(reconstructed.currentRound, equals(3));
    });
  });
}
