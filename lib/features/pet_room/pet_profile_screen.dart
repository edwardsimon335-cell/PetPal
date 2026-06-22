import 'package:flutter/material.dart';

import '../../app/petpal_controller.dart';
import '../../core/theme/petpal_theme.dart';
import '../../shared/widgets/pixel_page_scaffold.dart';
import '../../shared/widgets/pixel_pet_sprite.dart';

class PetProfileScreen extends StatefulWidget {
  const PetProfileScreen({required this.controller, super.key});

  final PetPalController controller;

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  late final TextEditingController nameController;
  bool editing = false;

  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: widget.controller.currentPet?.name ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final pet = widget.controller.currentPet;
        if (pet == null) return const SizedBox.shrink();

        return PixelPageScaffold(
          useRoomBackground: false,
          overlay: const LinearGradient(
            colors: [Color(0xFF2C1E13), Color(0xFF1B130C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          child: Column(
            children: [
              _DarkTopBar(
                  title: 'Pet Profile',
                  onBack: () => Navigator.of(context).pop()),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
                  children: [
                    Column(
                      children: [
                        PixelPetSprite(
                            role: pet.role,
                            variant: pet.avatarVariant,
                            size: 112),
                        const SizedBox(height: 8),
                        Text(
                          pet.name,
                          style: const TextStyle(
                            color: Color(0xFFFBECCF),
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _togetherText(pet.createdAt),
                          style: const TextStyle(
                            color: Color(0xFFA98E6A),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle('Basic Info'),
                    _DarkPanel(
                      children: [
                        _InfoRow(
                          label: 'Name',
                          value: pet.name,
                          trailing: IconButton(
                            onPressed: () {
                              setState(() => editing = !editing);
                            },
                            icon: const Icon(Icons.edit_outlined,
                                color: Color(0xFFEAD9BC), size: 18),
                          ),
                        ),
                        if (editing)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                            child: TextField(
                              controller: nameController,
                              style: const TextStyle(
                                  color: Color(0xFFFBECCF), letterSpacing: 0),
                              decoration: const InputDecoration(
                                isDense: true,
                                hintText: 'New name',
                              ),
                              onSubmitted: _commitName,
                            ),
                          ),
                        _InfoRow(label: 'Source', value: pet.sourceType.name),
                        _InfoRow(label: 'Species', value: pet.role.species),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const _SectionTitle('Personality'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final trait in pet.traits)
                          Chip(
                            label: Text(trait),
                            backgroundColor: const Color(0xFF3A2A1E),
                            labelStyle: const TextStyle(
                              color: Color(0xFFFBECCF),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                            side: const BorderSide(color: Color(0xFF6E5437)),
                          ),
                      ],
                    ),
                    if (pet.specialPersonalityDetail.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _DarkPanel(
                        children: [
                          _InfoRow(
                            label: 'Detail',
                            value: pet.specialPersonalityDetail,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),
                    const _SectionTitle('Status'),
                    _DarkPanel(
                      children: [
                        _Meter(
                            label: 'Mood',
                            value: pet.mood,
                            color: PetPalColors.heart),
                        _Meter(
                            label: 'Hunger',
                            value: pet.hunger,
                            color: PetPalColors.honey),
                        _Meter(
                            label: 'Clean',
                            value: pet.cleanliness,
                            color: PetPalColors.blue),
                      ],
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

  void _commitName(String value) {
    widget.controller.updateName(value);
    setState(() => editing = false);
  }

  String _togetherText(DateTime createdAt) {
    final days = DateTime.now().difference(createdAt).inDays + 1;
    return 'Together for $days ${days == 1 ? 'day' : 'days'}';
  }
}

class _DarkTopBar extends StatelessWidget {
  const _DarkTopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 8,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left_rounded,
                  color: Color(0xFFF3E4C4)),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF3E4C4),
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF9C7F5E),
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _DarkPanel extends StatelessWidget {
  const _DarkPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x10F7E9CD),
        border: Border.all(color: const Color(0x1AF7E9CD)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.trailing});

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFCBB697),
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFEAD9BC),
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Text(
              label,
              style: const TextStyle(
                  color: Color(0xFFCBB697),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 8,
                backgroundColor: const Color(0x22F7E9CD),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: Color(0xFFE0C79F),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0),
            ),
          ),
        ],
      ),
    );
  }
}
