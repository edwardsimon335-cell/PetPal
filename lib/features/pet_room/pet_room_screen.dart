import 'package:flutter/material.dart';
import 'package:pixelarticons/pixelarticons.dart';

import '../../app/page_transitions.dart';
import '../../app/petpal_controller.dart';
import '../../core/theme/petpal_theme.dart';
import '../../shared/widgets/pixel_button.dart';
import '../../shared/widgets/pixel_card.dart';
import '../../shared/widgets/pixel_page_scaffold.dart';
import '../../shared/widgets/status_bar.dart';
import '../settings/settings_screen.dart';
import 'pet_profile_screen.dart';
import 'widgets/chat_dialogue_area.dart';
import 'widgets/pet_stage.dart';

class PetRoomScreen extends StatelessWidget {
  const PetRoomScreen({required this.controller, super.key});

  final PetPalController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final pet = controller.currentPet;
        if (pet == null) {
          return const SizedBox.shrink();
        }
        return PixelPageScaffold(
          child: Stack(
            children: [
              Positioned(
                top: 16,
                left: 14,
                right: 14,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: PixelCard(
                        dark: true,
                        padding: const EdgeInsets.all(9),
                        onTap: () {
                          Navigator.of(context).push(
                            petPalRoute(
                              builder: (_) =>
                                  PetProfileScreen(controller: controller),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBECCF)
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Pixel.heart,
                                  color: Color(0xFFF3E4C4)),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pet.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFFFF7E6),
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    pet.statusText,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFDCC6A2),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Pixel.edit,
                                size: 17, color: Color(0xFFF3E4C4)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      onPressed: () {
                        Navigator.of(context).push(
                          petPalRoute(
                            builder: (_) =>
                                SettingsScreen(controller: controller),
                          ),
                        );
                      },
                      icon: const Icon(Pixel.sliders2),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            PetPalColors.ink.withValues(alpha: 0.78),
                        foregroundColor: const Color(0xFFF3E4C4),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 140,
                left: 16,
                width: 190,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showStatusDetails(context, controller),
                  child: Column(
                    children: [
                      PetStatusBar(
                        value: pet.mood,
                        color: PetPalColors.heart,
                        icon: Pixel.moodhappy,
                      ),
                      const SizedBox(height: 8),
                      PetStatusBar(
                        value: pet.hunger,
                        color: PetPalColors.honey,
                        icon: Pixel.coffee,
                      ),
                      const SizedBox(height: 8),
                      PetStatusBar(
                        value: pet.affinityProgressPercent,
                        color: const Color(0xFF9D74E8),
                        icon: Pixel.heart,
                        valueLabel: 'Lv.${pet.affinityLevel}',
                      ),
                      const SizedBox(height: 8),
                      PetStatusBar(
                        value: pet.cleanliness,
                        color: PetPalColors.blue,
                        icon: Pixel.drop,
                      ),
                    ],
                  ),
                ),
              ),
              if (controller.roomNotice != null)
                Positioned(
                  top: 92,
                  left: 18,
                  right: 18,
                  child: _RoomNotice(text: controller.roomNotice!),
                ),
              // The pet wanders the floor, naps, and reacts to taps; its speech
              // bubble follows it. Fills the stage but only the pet body is
              // tappable, so the bars above/below stay interactive.
              Positioned.fill(child: PetStage(controller: controller)),
              // Chat mode only: the user's latest message floats above the input
              // box (spec 3.3 / 2.2).
              if (controller.chatMode)
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 82,
                  child: ChatDialogueArea(controller: controller),
                ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 24,
                child: controller.chatMode
                    ? _ChatBar(controller: controller, petName: pet.name)
                    : _InteractionBar(controller: controller),
              ),
            ],
          ),
        );
      },
    );
  }
}

void _showStatusDetails(BuildContext context, PetPalController controller) {
  final pet = controller.currentPet;
  if (pet == null) return;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final next = pet.nextAffinityRequirement;
      final affinityDetail = next == null
          ? 'Max level reached.'
          : '${pet.affinity} / $next affinity';
      return Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2117),
          border: Border.all(color: const Color(0x55F7E9CD), width: 2),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0x77F7E9CD),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 14),
            _StatusDetailRow(
              icon: Pixel.moodhappy,
              label: 'Mood',
              value: '${pet.mood} / 100',
              detail: pet.moodLevelText,
              color: PetPalColors.heart,
            ),
            _StatusDetailRow(
              icon: Pixel.coffee,
              label: 'Hunger',
              value: '${pet.hunger} / 100',
              detail: pet.hungerLevelText,
              color: PetPalColors.honey,
            ),
            _StatusDetailRow(
              icon: Pixel.heart,
              label: 'Affinity',
              value: 'Lv.${pet.affinityLevel}',
              detail: '${pet.affinityLevelName} - $affinityDetail',
              color: const Color(0xFFB997FF),
            ),
            _StatusDetailRow(
              icon: Pixel.drop,
              label: 'Clean',
              value: '${pet.cleanliness} / 100',
              detail: 'Clean is kept from V1 and does not affect V1.1 mood.',
              color: PetPalColors.blue,
            ),
            const SizedBox(height: 10),
            Text(
              'Feed, caress, and chat to help ${pet.name} feel closer to you.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFCDB895),
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0,
              ),
            ),
            if (controller.feedCooldownLabel.isNotEmpty ||
                controller.caressCooldownLabel.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                [
                  if (controller.feedCooldownLabel.isNotEmpty)
                    'Feed ${controller.feedCooldownLabel}',
                  if (controller.caressCooldownLabel.isNotEmpty)
                    'Caress ${controller.caressCooldownLabel}',
                ].join('   '),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFEAD9BC),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0,
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _RoomNotice extends StatelessWidget {
  const _RoomNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 310),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xEEFFFAF0),
            border: Border.all(color: PetPalColors.line, width: 2),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: PetPalColors.softShadow.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PetPalColors.bark,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusDetailRow extends StatelessWidget {
  const _StatusDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0x18F7E9CD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFFFF7E6),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFCDB895),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFEAD9BC),
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractionBar extends StatelessWidget {
  const _InteractionBar({required this.controller});

  final PetPalController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: PixelButton(
            label: '',
            secondary: true,
            icon: const Icon(Pixel.chat, size: 21),
            onPressed: controller.toggleChatMode,
            height: 50,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PixelButton(
            label: 'Feed',
            secondary: true,
            icon: const Icon(Pixel.coffee, size: 19),
            onPressed: controller.feed,
            height: 50,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PixelButton(
            label: 'Clean',
            secondary: true,
            icon: const Icon(Pixel.drop, size: 19),
            onPressed: controller.clean,
            height: 50,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PixelButton(
            label: 'Caress',
            secondary: true,
            icon: const Icon(Pixel.moodhappy, size: 19),
            onPressed: controller.caress,
            height: 50,
          ),
        ),
      ],
    );
  }
}

class _ChatBar extends StatefulWidget {
  const _ChatBar({required this.controller, required this.petName});

  final PetPalController controller;
  final String petName;

  @override
  State<_ChatBar> createState() => _ChatBarState();
}

class _ChatBarState extends State<_ChatBar> {
  late final TextEditingController messageController;

  @override
  void initState() {
    super.initState();
    messageController = TextEditingController();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: PixelButton(
            label: '',
            secondary: true,
            icon: const Icon(Pixel.ksync, size: 21),
            onPressed: widget.controller.toggleChatMode,
            height: 50,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 50,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF2DA),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: PetPalColors.line, width: 2),
            ),
            child: TextField(
              controller: messageController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration.collapsed(
                hintText: 'Say something to ${widget.petName}',
                hintStyle: const TextStyle(
                  color: Color(0xFFA8895E),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              style: const TextStyle(
                color: PetPalColors.bark,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 50,
          child: PixelButton(
            label: '',
            icon: const Icon(Pixel.arrowup, size: 23),
            // Always enabled — rapid sends queue and are answered in order
            // (spec 3.3 "连续快速发送").
            onPressed: _send,
            height: 50,
          ),
        ),
      ],
    );
  }

  Future<void> _send() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;
    messageController.clear();
    await widget.controller.sendMessage(text);
  }
}
