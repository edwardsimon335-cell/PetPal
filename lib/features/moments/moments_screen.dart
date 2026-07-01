import 'package:flutter/material.dart';
import 'package:pixelarticons/pixelarticons.dart';

import '../../app/page_transitions.dart';
import '../../app/petpal_controller.dart';
import '../../core/theme/petpal_theme.dart';
import '../../shared/models/petpal_v12_models.dart';
import '../../shared/widgets/pixel_button.dart';
import '../../shared/widgets/pixel_card.dart';
import '../../shared/widgets/pixel_page_scaffold.dart';
import 'moment_detail_screen.dart';
import 'widgets/moment_art.dart';

class MomentsScreen extends StatefulWidget {
  const MomentsScreen({required this.controller, super.key});

  final PetPalController controller;

  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen> {
  MomentFilter _filter = MomentFilter.all;

  @override
  Widget build(BuildContext context) {
    final petName = widget.controller.currentPet?.name ?? 'your pet';
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final moments = widget.controller.visibleMoments(filter: _filter);
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
                            'Moments',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(
                            'Little memories with $petName.',
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
                child: _MomentFilterBar(
                  value: _filter,
                  onChanged: (value) => setState(() => _filter = value),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: moments.isEmpty
                    ? _EmptyMoments(petName: petName)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
                        itemBuilder: (context, index) {
                          final record = moments[index];
                          return PixelCard(
                            padding: const EdgeInsets.all(10),
                            onTap: () {
                              Navigator.of(context).push(
                                petPalRoute(
                                  builder: (_) => MomentDetailScreen(
                                    controller: widget.controller,
                                    record: record,
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 118,
                                  child: MomentArt(
                                    id: record.momentId,
                                    title: record.titleSnapshot,
                                    imageUrl: record.imageUrlSnapshot,
                                    compact: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        record.titleSnapshot,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: PetPalColors.bark,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        _dateLabel(record.createdAt),
                                        style: const TextStyle(
                                          color: PetPalColors.cocoa,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        record.diaryTextSnapshot,
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
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemCount: moments.length,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _dateLabel(DateTime date) {
    final local = date.toLocal();
    return '${local.year}.${local.month.toString().padLeft(2, '0')}.${local.day.toString().padLeft(2, '0')}';
  }
}

class _MomentFilterBar extends StatelessWidget {
  const _MomentFilterBar({required this.value, required this.onChanged});

  final MomentFilter value;
  final ValueChanged<MomentFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: PetPalColors.ink.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PetPalColors.line, width: 2),
      ),
      child: Row(
        children: [
          _FilterButton(
            label: 'All',
            selected: value == MomentFilter.all,
            onTap: () => onChanged(MomentFilter.all),
          ),
          _FilterButton(
            label: 'Home',
            selected: value == MomentFilter.home,
            onTap: () => onChanged(MomentFilter.home),
          ),
          _FilterButton(
            label: 'Special',
            selected: value == MomentFilter.special,
            onTap: () => onChanged(MomentFilter.special),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? PetPalColors.honey : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : PetPalColors.cocoa,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyMoments extends StatelessWidget {
  const _EmptyMoments({required this.petName});

  final String petName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: PixelCard(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Pixel.heart, size: 44, color: PetPalColors.honey),
              const SizedBox(height: 12),
              const Text(
                'No moments yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: PetPalColors.bark,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Spend more time with $petName, and little memories will appear here.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: PetPalColors.cocoa,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 18),
              PixelButton(
                label: 'Back Home',
                secondary: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
