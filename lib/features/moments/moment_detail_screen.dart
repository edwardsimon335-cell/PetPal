import 'package:flutter/material.dart';
import 'package:pixelarticons/pixelarticons.dart';

import '../../app/petpal_controller.dart';
import '../../core/theme/petpal_theme.dart';
import '../../shared/models/petpal_v12_models.dart';
import '../../shared/widgets/pixel_card.dart';
import '../../shared/widgets/pixel_page_scaffold.dart';
import 'widgets/moment_art.dart';

class MomentDetailScreen extends StatelessWidget {
  const MomentDetailScreen({
    required this.controller,
    required this.record,
    super.key,
  });

  final PetPalController controller;
  final UserMomentRecord record;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (record.isDeleted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).maybePop();
          });
        }
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
                    const Spacer(),
                    IconButton.filled(
                      onPressed: () => _confirmDelete(context),
                      icon: const Icon(Pixel.trash),
                      style: IconButton.styleFrom(
                        backgroundColor: PetPalColors.heart,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                  children: [
                    MomentArt(
                      id: record.momentId,
                      title: record.titleSnapshot,
                      imageUrl: record.imageUrlSnapshot,
                    ),
                    const SizedBox(height: 16),
                    PixelCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.titleSnapshot,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _Tag(label: _dateLabel(record.createdAt)),
                              _Tag(
                                  label: _typeLabel(record.momentTypeSnapshot)),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            record.diaryTextSnapshot,
                            style: const TextStyle(
                              color: PetPalColors.cocoa,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PetPalColors.cream,
        title: const Text('Delete this moment?'),
        content: const Text(
          'This memory will be removed from your Moments.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: PetPalColors.heart),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await controller.deleteMoment(record);
    if (context.mounted) Navigator.of(context).pop();
  }

  static String _dateLabel(DateTime date) {
    final local = date.toLocal();
    return '${local.year}.${local.month.toString().padLeft(2, '0')}.${local.day.toString().padLeft(2, '0')}';
  }

  static String _typeLabel(String type) {
    if (type == 'special') return 'Special';
    if (type == 'dream') return 'Dream';
    return 'Home';
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: PetPalColors.honey.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PetPalColors.line),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: PetPalColors.bark,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
