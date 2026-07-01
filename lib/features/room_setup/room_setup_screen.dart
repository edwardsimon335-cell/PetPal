import 'package:flutter/material.dart';
import 'package:pixelarticons/pixelarticons.dart';

import '../../app/petpal_controller.dart';
import '../../core/theme/petpal_theme.dart';
import '../../shared/models/petpal_v12_models.dart';
import '../../shared/widgets/pixel_button.dart';
import '../../shared/widgets/pixel_card.dart';
import '../../shared/widgets/pixel_page_scaffold.dart';
import 'widgets/room_item_glyph.dart';

class RoomSetupScreen extends StatelessWidget {
  const RoomSetupScreen({required this.controller, super.key});

  final PetPalController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final pet = controller.currentPet;
        final items = controller.roomItems;
        final placedCount = pet?.placedItemIds.length ?? 0;
        return PixelPageScaffold(
          useRoomBackground: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Row(
                  children: [
                    IconButton.filled(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Pixel.arrowleft),
                      style: IconButton.styleFrom(
                        backgroundColor: PetPalColors.ink,
                        foregroundColor: PetPalColors.cream,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set Up Room',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(
                            'Leave something cozy for ${pet?.name ?? 'your pet'}.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: PixelCard(
                  dark: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(Pixel.heart, color: PetPalColors.cream),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$placedCount / 3 placed',
                          style: const TextStyle(
                            color: PetPalColors.cream,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      Text(
                        'Affinity Lv.${pet?.affinityLevel ?? 1}',
                        style: const TextStyle(
                          color: Color(0xFFDCC6A2),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: items.isEmpty
                    ? const _ConfigEmpty()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final selected =
                              pet?.placedItemIds.contains(item.itemId) ?? false;
                          final unlocked = pet == null || item.isUnlocked(pet);
                          return _RoomItemCard(
                            item: item,
                            selected: selected,
                            unlocked: unlocked,
                            onTap: () => controller.toggleRoomItem(item),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemCount: items.length,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                child: PixelButton(
                  label: 'Back Home',
                  secondary: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoomItemCard extends StatelessWidget {
  const _RoomItemCard({
    required this.item,
    required this.selected,
    required this.unlocked,
    required this.onTap,
  });

  final RoomItemConfig item;
  final bool selected;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PixelCard(
      selected: selected,
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          RoomItemGlyph(itemId: item.itemId, dimmed: !unlocked),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.itemName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: PetPalColors.bark,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    _StatusPill(
                      label: selected
                          ? 'Placed'
                          : unlocked
                              ? 'Available'
                              : 'Locked',
                      selected: selected,
                      locked: !unlocked,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PetPalColors.cocoa,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    letterSpacing: 0,
                  ),
                ),
                if (!unlocked) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Reach Affinity Lv.${item.unlockAffinityLevel} to unlock.',
                    style: const TextStyle(
                      color: PetPalColors.heart,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.selected,
    required this.locked,
  });

  final String label;
  final bool selected;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final color = locked
        ? PetPalColors.cocoa
        : selected
            ? PetPalColors.honey
            : PetPalColors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ConfigEmpty extends StatelessWidget {
  const _ConfigEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Room setup is taking a tiny nap.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: PetPalColors.cocoa,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
