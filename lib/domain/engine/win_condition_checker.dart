import '../entities/game_player.dart';

enum WinResult {
  townWin,
  mafiaWin,
  jesterWin,
  maniacWin,
  inProgress;

  String? get teamKey {
    switch (this) {
      case WinResult.townWin:
        return 'town';
      case WinResult.mafiaWin:
        return 'mafia';
      case WinResult.jesterWin:
        return 'jester';
      case WinResult.maniacWin:
        return 'maniac';
      case WinResult.inProgress:
        return null;
    }
  }

  static WinResult fromTeamKey(String? key) {
    switch (key?.toLowerCase()) {
      case 'town':
        return WinResult.townWin;
      case 'mafia':
        return WinResult.mafiaWin;
      case 'jester':
        return WinResult.jesterWin;
      case 'maniac':
        return WinResult.maniacWin;
      default:
        return WinResult.inProgress;
    }
  }

  String get title {
    switch (this) {
      case WinResult.townWin:
        return 'Town Victory!';
      case WinResult.mafiaWin:
        return 'Mafia Syndicate Victory!';
      case WinResult.jesterWin:
        return 'Jester Victory!';
      case WinResult.maniacWin:
        return 'Maniac Victory!';
      case WinResult.inProgress:
        return 'Game in Progress';
    }
  }

  String get subtitle {
    switch (this) {
      case WinResult.townWin:
        return 'Justice reigns. All members of the Syndicate have been eliminated.';
      case WinResult.mafiaWin:
        return 'The Syndicate has taken over the city. The town has fallen.';
      case WinResult.jesterWin:
        return 'The Jester tricked the entire town into an execution and wins alone!';
      case WinResult.maniacWin:
        return 'The solitary killer stands victorious over the fallen city.';
      case WinResult.inProgress:
        return '';
    }
  }
}

class WinConditionChecker {
  static WinResult check({
    required List<GamePlayer> allPlayers,
    bool jesterExecutedToday = false,
  }) {
    // 1. Jester immediate day vote win
    if (jesterExecutedToday) {
      return WinResult.jesterWin;
    }

    final livingPlayers = allPlayers.where((p) => p.isAlive).toList();
    if (livingPlayers.isEmpty) {
      return WinResult.townWin; // Fallback edge case
    }

    // Check Maniac
    final maniacLiving = livingPlayers.any((p) => p.roleKey == 'maniac');
    if (maniacLiving && livingPlayers.length <= 2) {
      return WinResult.maniacWin;
    }

    // Count Mafia (Don + Mafia)
    final livingMafia = livingPlayers.where((p) => p.roleTeam == 'mafia').length;
    final livingNonMafia = livingPlayers.length - livingMafia;

    // 2. Town win condition: all Mafia eliminated
    if (livingMafia == 0) {
      return WinResult.townWin;
    }

    // 3. Mafia win condition: Mafia equal or outnumber non-Mafia
    if (livingMafia >= livingNonMafia) {
      return WinResult.mafiaWin;
    }

    return WinResult.inProgress;
  }
}
