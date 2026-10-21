import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/game_constants.dart';
import '../../domain/entities/game_settings.dart';
import '../../domain/entities/player.dart';
import '../../domain/entities/role.dart';
import '../../domain/repositories/player_repository.dart';
import '../../domain/repositories/role_repository.dart';
import '../../domain/repositories/settings_repository.dart';

class GameSetupState extends Equatable {
  final List<Player> availablePlayers;
  final Set<int> selectedPlayerIds;
  final List<Player> guestPlayers;
  final List<Role> allRoles;
  final Set<String> enabledRoleKeys;
  final Map<String, int> roleCounts;
  final GameSettings settings;
  final bool isLoading;
  final String? errorMessage;

  const GameSetupState({
    this.availablePlayers = const [],
    this.selectedPlayerIds = const {},
    this.guestPlayers = const [],
    this.allRoles = const [],
    this.enabledRoleKeys = const {},
    this.roleCounts = const {},
    this.settings = const GameSettings(),
    this.isLoading = false,
    this.errorMessage,
  });

  int get totalSelectedCount => selectedPlayerIds.length + guestPlayers.length;

  int get totalAssignedRolesCount => roleCounts.values.fold(0, (a, b) => a + b);

  int get mafiaCount => (roleCounts['don'] ?? 0) + (roleCounts['mafia'] ?? 0);

  bool get isMafiaCountValid {
    if (totalSelectedCount < GameConstants.minPlayers) return false;
    final mCount = mafiaCount;
    // Mafia must be > 0 and strictly less than half the total players (PRD F6)
    return mCount > 0 && mCount < (totalSelectedCount / 2);
  }

  String? get balanceWarning {
    if (totalSelectedCount < GameConstants.minPlayers) {
      return 'Select at least ${GameConstants.minPlayers} players to begin.';
    }
    final mCount = mafiaCount;
    if (mCount == 0) {
      return 'Warning: No Mafia members assigned! The town needs an adversary.';
    }
    final nonCivilianSum = roleCounts.entries
        .where((e) => e.key != 'civilian' && enabledRoleKeys.contains(e.key))
        .fold(0, (sum, e) => sum + e.value);
    if (nonCivilianSum > totalSelectedCount) {
      final excess = nonCivilianSum - totalSelectedCount;
      return 'Too many special roles assigned ($nonCivilianSum) for $totalSelectedCount players. Reduce other roles by $excess.';
    }
    final diff = totalSelectedCount - totalAssignedRolesCount;
    if (diff > 0) {
      return '$diff more role slot(s) needed to match player count.';
    }
    if (diff < 0) {
      return '${-diff} too many roles assigned for $totalSelectedCount players.';
    }
    return null;
  }

  bool get canStartGame =>
      totalSelectedCount >= GameConstants.minPlayers &&
      totalAssignedRolesCount == totalSelectedCount &&
      isMafiaCountValid;

  List<Player> get allParticipatingPlayers {
    final list = <Player>[];
    for (final p in availablePlayers) {
      if (selectedPlayerIds.contains(p.id)) {
        list.add(p);
      }
    }
    list.addAll(guestPlayers);
    return list;
  }

  GameSetupState copyWith({
    List<Player>? availablePlayers,
    Set<int>? selectedPlayerIds,
    List<Player>? guestPlayers,
    List<Role>? allRoles,
    Set<String>? enabledRoleKeys,
    Map<String, int>? roleCounts,
    GameSettings? settings,
    bool? isLoading,
    String? errorMessage,
  }) {
    return GameSetupState(
      availablePlayers: availablePlayers ?? this.availablePlayers,
      selectedPlayerIds: selectedPlayerIds ?? this.selectedPlayerIds,
      guestPlayers: guestPlayers ?? this.guestPlayers,
      allRoles: allRoles ?? this.allRoles,
      enabledRoleKeys: enabledRoleKeys ?? this.enabledRoleKeys,
      roleCounts: roleCounts ?? this.roleCounts,
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        availablePlayers,
        selectedPlayerIds,
        guestPlayers,
        allRoles,
        enabledRoleKeys,
        roleCounts,
        settings,
        isLoading,
        errorMessage,
      ];
}

class GameSetupCubit extends Cubit<GameSetupState> {
  final PlayerRepository _playerRepo;
  final RoleRepository _roleRepo;
  final SettingsRepository _settingsRepo;

  GameSetupCubit({
    required PlayerRepository playerRepository,
    required RoleRepository roleRepository,
    required SettingsRepository settingsRepository,
  })  : _playerRepo = playerRepository,
        _roleRepo = roleRepository,
        _settingsRepo = settingsRepository,
        super(const GameSetupState());

  Future<void> init() async {
    emit(state.copyWith(isLoading: true));
    try {
      final players = await _playerRepo.getPlayers(includeDeleted: false);
      final roles = await _roleRepo.getAllRoles();
      final settings = await _settingsRepo.getSettings();

      final enabled = <String>{};
      for (final r in roles) {
        if (r.defaultEnabled) {
          enabled.add(r.key);
        }
      }

      // Default select up to 8 players if available
      final initialSelected = <int>{};
      for (int i = 0; i < players.length && i < 8; i++) {
        if (players[i].id != null) initialSelected.add(players[i].id!);
      }

      final initialCounts = GameConstants.getRecommendedRoles(
        initialSelected.length,
        enabledRoleKeys: enabled,
      );

      emit(state.copyWith(
        availablePlayers: players,
        selectedPlayerIds: initialSelected,
        allRoles: roles,
        enabledRoleKeys: enabled,
        roleCounts: initialCounts,
        settings: settings,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: 'Failed to init setup: $e'));
    }
  }

  void togglePlayer(int playerId) {
    final updated = Set<int>.from(state.selectedPlayerIds);
    if (updated.contains(playerId)) {
      updated.remove(playerId);
    } else {
      updated.add(playerId);
    }
    _updateSelection(updated, state.guestPlayers);
  }

  void selectAllPlayers() {
    final updated = state.availablePlayers.map((p) => p.id!).toSet();
    _updateSelection(updated, state.guestPlayers);
  }

  void clearAllPlayers() {
    _updateSelection(<int>{}, []);
  }

  void addGuestPlayer(String guestName, int color, bool saveToRoster) async {
    final trimmed = guestName.trim();
    if (trimmed.isEmpty) return;

    if (saveToRoster) {
      final newPlayer = Player(
        name: trimmed,
        color: color,
        createdAt: DateTime.now(),
      );
      final id = await _playerRepo.insertPlayer(newPlayer);
      final freshPlayers = await _playerRepo.getPlayers(includeDeleted: false);
      final updatedSelected = Set<int>.from(state.selectedPlayerIds)..add(id);

      emit(state.copyWith(availablePlayers: freshPlayers));
      _updateSelection(updatedSelected, state.guestPlayers);
    } else {
      final guest = Player(
        id: -100 - state.guestPlayers.length,
        name: '$trimmed (Guest)',
        color: color,
        createdAt: DateTime.now(),
      );
      final updatedGuests = List<Player>.from(state.guestPlayers)..add(guest);
      _updateSelection(state.selectedPlayerIds, updatedGuests);
    }
  }

  Map<String, int> _autoBalanceCivilian(
    Map<String, int> counts,
    int totalPlayers,
    Set<String> enabledKeys,
  ) {
    final updated = Map<String, int>.from(counts);
    int nonCivilianSum = 0;
    updated.forEach((key, val) {
      if (key != 'civilian' && enabledKeys.contains(key)) {
        nonCivilianSum += val;
      }
    });

    final remaining = (totalPlayers - nonCivilianSum).clamp(0, totalPlayers);
    updated['civilian'] = remaining;

    if (remaining > 0) {
      enabledKeys.add('civilian');
    } else {
      updated['civilian'] = 0;
    }

    return updated;
  }

  void _updateSelection(Set<int> selectedIds, List<Player> guests) {
    final totalCount = selectedIds.length + guests.length;
    // Auto-update suggested roles if counts match
    final recommended = GameConstants.getRecommendedRoles(
      totalCount,
      enabledRoleKeys: state.enabledRoleKeys,
    );
    final updatedEnabled = Set<String>.from(state.enabledRoleKeys);
    final balanced = _autoBalanceCivilian(recommended, totalCount, updatedEnabled);

    emit(state.copyWith(
      selectedPlayerIds: selectedIds,
      guestPlayers: guests,
      roleCounts: balanced,
      enabledRoleKeys: updatedEnabled,
    ));
  }

  void toggleRoleEnabled(String roleKey, bool isEnabled) {
    if (roleKey == 'civilian') {
      // Civilian represents all remaining unassigned players
      return;
    }

    final updatedEnabled = Set<String>.from(state.enabledRoleKeys);
    final updatedCounts = Map<String, int>.from(state.roleCounts);

    if (isEnabled) {
      updatedEnabled.add(roleKey);
      if ((updatedCounts[roleKey] ?? 0) == 0) {
        updatedCounts[roleKey] = 1;
      }
    } else {
      updatedEnabled.remove(roleKey);
      updatedCounts[roleKey] = 0;
    }

    final balanced = _autoBalanceCivilian(
      updatedCounts,
      state.totalSelectedCount,
      updatedEnabled,
    );

    emit(state.copyWith(
      enabledRoleKeys: updatedEnabled,
      roleCounts: balanced,
    ));
  }

  void setRoleCount(String roleKey, int count) {
    if (roleKey == 'civilian') {
      // Civilian represents all remaining unassigned players
      return;
    }

    final updatedCounts = Map<String, int>.from(state.roleCounts);
    final updatedEnabled = Set<String>.from(state.enabledRoleKeys);

    if (count <= 0) {
      updatedCounts[roleKey] = 0;
      updatedEnabled.remove(roleKey);
    } else {
      updatedCounts[roleKey] = count;
      updatedEnabled.add(roleKey);
    }

    final balanced = _autoBalanceCivilian(
      updatedCounts,
      state.totalSelectedCount,
      updatedEnabled,
    );

    emit(state.copyWith(
      roleCounts: balanced,
      enabledRoleKeys: updatedEnabled,
    ));
  }

  void autoBalanceRoles() {
    final recommended = GameConstants.getRecommendedRoles(
      state.totalSelectedCount,
      enabledRoleKeys: state.enabledRoleKeys,
    );
    final updatedEnabled = Set<String>.from(state.enabledRoleKeys);
    final balanced = _autoBalanceCivilian(
      recommended,
      state.totalSelectedCount,
      updatedEnabled,
    );
    emit(state.copyWith(
      roleCounts: balanced,
      enabledRoleKeys: updatedEnabled,
    ));
  }
}
