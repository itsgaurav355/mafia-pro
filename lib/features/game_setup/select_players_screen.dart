import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/game_constants.dart';
import '../../core/widgets/atmospheric_background.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/player_avatar.dart';
import 'game_setup_cubit.dart';
import 'role_setup_screen.dart';

class SelectPlayersScreen extends StatefulWidget {
  const SelectPlayersScreen({super.key});

  @override
  State<SelectPlayersScreen> createState() => _SelectPlayersScreenState();
}

class _SelectPlayersScreenState extends State<SelectPlayersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddGuestDialog(BuildContext parentContext) {
    final guestNameController = TextEditingController();
    int selectedColor = AppColors.playerAvatarColors[0].toARGB32();
    bool saveToRoster = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'QUICK ADD GUEST',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: guestNameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Guest Name',
                      hintText: 'e.g. Alex',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppColors.playerAvatarColors.take(6).map((color) {
                      final isSelected = selectedColor == color.toARGB32();
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedColor = color.toARGB32()),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Save to permanent roster for future games'),
                    value: saveToRoster,
                    activeColor: AppColors.mafia,
                    onChanged: (val) => setModalState(() => saveToRoster = val ?? false),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final name = guestNameController.text.trim();
                      if (name.isNotEmpty) {
                        parentContext.read<GameSetupCubit>().addGuestPlayer(
                              name,
                              selectedColor,
                              saveToRoster,
                            );
                        Navigator.of(context).pop();
                      }
                    },
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'ADD GUEST TO TONIGHT’S GAME',
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AtmosphericBackground(
      mood: AtmosphereMood.noir,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('SELECT PLAYERS'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add_alt_1_rounded),
              tooltip: 'Quick Add Guest',
              onPressed: () => _showAddGuestDialog(context),
            ),
          ],
        ),
        bottomNavigationBar: BlocBuilder<GameSetupCubit, GameSetupState>(
          builder: (context, state) {
            final count = state.totalSelectedCount;
            final isValid = count >= GameConstants.minPlayers;

            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$count PLAYERS',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          isValid ? 'Ready to configure' : 'Min ${GameConstants.minPlayers} required',
                          style: TextStyle(
                            color: isValid ? AppColors.success : AppColors.textMuted,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: isValid
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: context.read<GameSetupCubit>(),
                                  child: const RoleSetupScreen(),
                                ),
                              ),
                            );
                          }
                        : null,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('NEXT: ROLES'),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        body: BlocBuilder<GameSetupCubit, GameSetupState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final filtered = state.availablePlayers.where((p) {
              if (_filter.isEmpty) return true;
              return p.name.toLowerCase().contains(_filter) ||
                  (p.nickname != null && p.nickname!.toLowerCase().contains(_filter));
            }).toList();

            return Column(
              children: [
                // Quick actions & search
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _filter = val.trim().toLowerCase()),
                          decoration: InputDecoration(
                            hintText: 'Filter players...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            suffixIcon: _filter.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _filter = '');
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () => context.read<GameSetupCubit>().selectAllPlayers(),
                        child: const Text('ALL'),
                      ),
                      TextButton(
                        onPressed: () => context.read<GameSetupCubit>().clearAllPlayers(),
                        child: const Text('CLEAR'),
                      ),
                    ],
                  ),
                ),

                // Guest banner if any guests present
                if (state.guestPlayers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.neutral.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.neutral.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.group_add_rounded, color: AppColors.neutral, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Guests added: ${state.guestPlayers.map((g) => g.name).join(', ')}',
                              style: const TextStyle(color: AppColors.neutral, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Players List
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyState(
                          lottieAsset: 'empty_box',
                          icon: Icons.person_off_rounded,
                          title: 'No Players Found',
                          message: state.availablePlayers.isEmpty
                              ? 'Your roster is empty. Add players from the Roster tab or quick add a guest.'
                              : 'No players match your search filter.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final player = filtered[index];
                            final isSelected = state.selectedPlayerIds.contains(player.id);

                            return GlowCard(
                              isSelected: isSelected,
                              glowColor: AppColors.mafiaGlow,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              onTap: () => context.read<GameSetupCubit>().togglePlayer(player.id!),
                              child: Row(
                                children: [
                                  PlayerAvatar(
                                    name: player.name,
                                    colorValue: player.color,
                                    radius: 20,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      player.displayName,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : AppColors.textSecondary,
                                        fontSize: 15,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? AppColors.mafia : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected ? AppColors.mafia : AppColors.surfaceBorderLight,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                                        : null,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
