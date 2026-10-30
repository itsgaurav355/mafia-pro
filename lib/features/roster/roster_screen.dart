import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/atmospheric_background.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/player_avatar.dart';
import '../../domain/entities/player.dart';
import 'roster_cubit.dart';

class RosterScreen extends StatefulWidget {
  const RosterScreen({super.key});

  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditPlayerDialog({Player? existingPlayer}) {
    final nameController = TextEditingController(text: existingPlayer?.name ?? '');
    final nicknameController = TextEditingController(text: existingPlayer?.nickname ?? '');
    int selectedColor = existingPlayer?.color ?? AppColors.playerAvatarColors[0].toARGB32();
    String? errorMessage;

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existingPlayer == null ? 'ADD NEW PLAYER' : 'EDIT PLAYER',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Player Name *',
                      hintText: 'e.g. Vincent',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nicknameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nickname (Optional)',
                      hintText: 'e.g. The Enforcer',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'AVATAR COLOR',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: AppColors.playerAvatarColors.map((color) {
                      final isSelected = selectedColor == color.toARGB32();
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedColor = color.toARGB32()),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.6),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        setModalState(() => errorMessage = 'Name is required');
                        return;
                      }

                      final nicknameText = nicknameController.text.trim();
                      final nicknameVal = nicknameText.isEmpty ? null : nicknameText;

                      final cubit = context.read<RosterCubit>();
                      bool success;
                      if (existingPlayer == null) {
                        success = await cubit.addPlayer(
                          name: name,
                          nickname: nicknameVal,
                          color: selectedColor,
                        );
                      } else {
                        success = await cubit.editPlayer(
                          existingPlayer.copyWith(
                            name: name,
                            nickname: nicknameVal,
                            color: selectedColor,
                          ),
                        );
                      }

                      if (!success) {
                        setModalState(() =>
                            errorMessage = 'A player with this name already exists!');
                      } else {
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      }
                    },
                    child: Text(existingPlayer == null ? 'SAVE TO ROSTER' : 'UPDATE PLAYER'),
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
          title: const Text('PLAYER ROSTER'),
          actions: [
            // Delete All Players button
            BlocBuilder<RosterCubit, RosterState>(
              builder: (context, state) {
                final hasPlayers = state is RosterLoaded && state.players.isNotEmpty;
                if (!hasPlayers) return const SizedBox.shrink();

                return IconButton(
                  icon: const Icon(
                    Icons.delete_sweep_rounded,
                    color: AppColors.error,
                  ),
                  tooltip: 'Remove All Players',
                  onPressed: () async {
                    final cubit = context.read<RosterCubit>();
                    final count = state.players.length;
                    final confirmed = await ConfirmDialog.show(
                      context: context,
                      title: 'Remove All Players?',
                      message:
                          'Are you sure you want to remove all $count players from your active roster? Past game stats will still be safely preserved.',
                      confirmText: 'REMOVE ALL',
                      confirmColor: AppColors.error,
                      icon: Icons.delete_sweep_rounded,
                    );

                    if (confirmed && context.mounted) {
                      await cubit.deleteAllPlayers();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All players removed from roster'),
                          ),
                        );
                      }
                    }
                  },
                );
              },
            ),
            // Sort / Order mode button
            BlocBuilder<RosterCubit, RosterState>(
              builder: (context, state) {
                IconData sortIcon = Icons.swap_vert_rounded;
                String sortTooltip = 'Sort: Custom Order (Drag to Reorder)';
                if (state is RosterLoaded) {
                  if (state.sortBy == 'name') {
                    sortIcon = Icons.sort_by_alpha_rounded;
                    sortTooltip = 'Sort: Alphabetical (A-Z)';
                  } else if (state.sortBy == 'last_played') {
                    sortIcon = Icons.history_rounded;
                    sortTooltip = 'Sort: Recently Played';
                  }
                }

                return IconButton(
                  icon: Icon(sortIcon, color: AppColors.textPrimary),
                  tooltip: sortTooltip,
                  onPressed: () => context.read<RosterCubit>().toggleSort(),
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddEditPlayerDialog(),
          backgroundColor: AppColors.mafia,
          icon: const Icon(Icons.person_add_rounded, color: Colors.white),
          label: const Text(
            'ADD PLAYER',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
        body: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => context.read<RosterCubit>().search(val),
                decoration: InputDecoration(
                  hintText: 'Search roster by name or nickname...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            context.read<RosterCubit>().search('');
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Players List
            Expanded(
              child: BlocBuilder<RosterCubit, RosterState>(
                builder: (context, state) {
                  if (state is RosterLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is RosterError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    );
                  }

                  if (state is RosterLoaded) {
                    final players = state.players;

                    if (players.isEmpty) {
                      return EmptyState(
                        lottieAsset: 'empty_box',
                        icon: Icons.people_outline_rounded,
                        title: 'No Players Found',
                        message: state.searchQuery.isEmpty
                            ? 'Your roster is currently empty. Tap Add Player to begin building your crew!'
                            : 'No saved player matches "${state.searchQuery}".',
                        buttonText: state.searchQuery.isEmpty ? 'Add First Player' : null,
                        onButtonPressed: state.searchQuery.isEmpty
                            ? () => _showAddEditPlayerDialog()
                            : null,
                      );
                    }

                    final canReorder = state.searchQuery.isEmpty && state.sortBy == 'custom';

                    return ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: players.length,
                      onReorderItem: (oldIndex, newIndex) {
                        context.read<RosterCubit>().reorderPlayers(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final player = players[index];
                        final lastPlayedFormatted = player.lastPlayedAt != null
                            ? DateFormat.yMMMd().format(player.lastPlayedAt!)
                            : 'Never played';

                        return GlowCard(
                          key: ValueKey(player.id ?? index),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          onTap: () => _showAddEditPlayerDialog(existingPlayer: player),
                          child: Row(
                            children: [
                              if (canReorder)
                                ReorderableDragStartListener(
                                  index: index,
                                  child: const Padding(
                                    padding: EdgeInsets.only(right: 10),
                                    child: Icon(
                                      Icons.drag_indicator_rounded,
                                      color: AppColors.textMuted,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              PlayerAvatar(
                                name: player.name,
                                colorValue: player.color,
                                radius: 22,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      player.displayName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Last game: $lastPlayedFormatted',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    size: 20, color: AppColors.textSecondary),
                                onPressed: () =>
                                    _showAddEditPlayerDialog(existingPlayer: player),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 20, color: AppColors.error),
                                onPressed: () async {
                                  final confirmed = await ConfirmDialog.show(
                                    context: context,
                                    title: 'Remove Player?',
                                    message:
                                        'Remove ${player.name} from the active roster? Past game records will still be preserved.',
                                    confirmText: 'Remove',
                                    confirmColor: AppColors.error,
                                    icon: Icons.delete_forever_rounded,
                                  );

                                  if (confirmed && context.mounted) {
                                    final cubit = context.read<RosterCubit>();
                                    await cubit.deletePlayer(player.id!);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${player.name} removed'),
                                          action: SnackBarAction(
                                            label: 'UNDO',
                                            textColor: AppColors.mafiaGlow,
                                            onPressed: () =>
                                                cubit.restorePlayer(player.id!),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
