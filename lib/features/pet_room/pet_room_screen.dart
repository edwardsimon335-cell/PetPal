import 'package:flutter/material.dart';

import '../../app/petpal_controller.dart';
import '../../core/theme/petpal_theme.dart';
import '../../shared/widgets/pixel_button.dart';
import '../../shared/widgets/pixel_card.dart';
import '../../shared/widgets/pixel_page_scaffold.dart';
import '../../shared/widgets/pixel_pet_sprite.dart';
import '../../shared/widgets/speech_bubble.dart';
import '../../shared/widgets/status_bar.dart';
import '../settings/settings_screen.dart';
import 'pet_profile_screen.dart';

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
                            MaterialPageRoute(
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
                              child: const Icon(Icons.pets_rounded,
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
                            const Icon(Icons.edit_outlined,
                                size: 17, color: Color(0xFFF3E4C4)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                SettingsScreen(controller: controller),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings_outlined),
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
                top: 112,
                left: 16,
                width: 172,
                child: Column(
                  children: [
                    PetStatusBar(
                        value: pet.mood,
                        color: PetPalColors.heart,
                        icon: Icons.favorite_rounded),
                    const SizedBox(height: 9),
                    PetStatusBar(
                        value: pet.hunger,
                        color: PetPalColors.honey,
                        icon: Icons.set_meal_rounded),
                    const SizedBox(height: 9),
                    PetStatusBar(
                        value: pet.cleanliness,
                        color: PetPalColors.blue,
                        icon: Icons.auto_awesome_rounded),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: MediaQuery.of(context).size.height * 0.34,
                child: SpeechBubble(text: controller.latestBubble),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 110,
                child: Center(
                  child: PixelPetSprite(
                    role: pet.role,
                    variant: pet.avatarVariant,
                    size: 176,
                  ),
                ),
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
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 21),
            onPressed: controller.toggleChatMode,
            height: 50,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PixelButton(
            label: 'Feed',
            secondary: true,
            icon: const Icon(Icons.set_meal_rounded, size: 19),
            onPressed: controller.feed,
            height: 50,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PixelButton(
            label: 'Clean',
            secondary: true,
            icon: const Icon(Icons.bathtub_outlined, size: 19),
            onPressed: controller.clean,
            height: 50,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PixelButton(
            label: 'Pet',
            secondary: true,
            icon: const Icon(Icons.back_hand_outlined, size: 19),
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
            icon: const Icon(Icons.sync_rounded, size: 21),
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
            icon: const Icon(Icons.arrow_upward_rounded, size: 23),
            onPressed: widget.controller.chatBusy ? null : _send,
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
