import 'package:flutter/foundation.dart';

import '../shared/models/pet_profile.dart';
import '../shared/models/preset_role.dart';
import '../shared/repositories/mock_pet_repository.dart';

class PetPalController extends ChangeNotifier {
  PetPalController({MockPetRepository repository = const MockPetRepository()})
      : _repository = repository {
    roles = _repository.presetRoles();
  }

  final MockPetRepository _repository;

  late final List<PresetRole> roles;
  int? selectedAvatarVariant;
  PresetRole? selectedRole;
  PetProfile? currentPet;
  String latestBubble = 'I missed you. Want to play?';
  bool chatMode = false;

  static const allTraits = [
    'Lazy',
    'Affectionate',
    'Sassy',
    'Chatty',
    'Playful',
    'Foodie',
    'Cool',
    'Gentle',
    'Curious',
    'Shy',
  ];

  PresetRole uploadedPlaceholder(int variant) {
    return _repository.uploadedPlaceholder(variant);
  }

  void selectGeneratedAvatar(int variant) {
    selectedAvatarVariant = variant;
    notifyListeners();
  }

  void selectRole(PresetRole role) {
    selectedRole = role;
    notifyListeners();
  }

  void createUploadedPet({
    required String name,
    required List<String> traits,
  }) {
    final variant = selectedAvatarVariant ?? 0;
    currentPet = PetProfile(
      name: name.trim().isEmpty ? 'Mochi' : name.trim(),
      sourceType: PetSourceType.uploadedPhoto,
      traits: traits,
      role: uploadedPlaceholder(variant),
      avatarVariant: variant,
      generationStatus: 'generating',
      statusText: 'Generating final avatar',
    );
    latestBubble = 'What should we do first?';
    notifyListeners();
  }

  void createPresetPet({
    required String name,
    required List<String> traits,
  }) {
    final role = selectedRole ?? roles.first;
    currentPet = PetProfile(
      name: name.trim().isEmpty ? role.name : name.trim(),
      sourceType: PetSourceType.presetRole,
      traits: traits.isEmpty ? role.defaultTraits : traits,
      role: role,
      generationStatus: 'none',
      statusText: 'Feeling cozy',
    );
    latestBubble = 'I am home!';
    notifyListeners();
  }

  void updateName(String name) {
    final pet = currentPet;
    if (pet == null) return;
    pet.name = name.trim().isEmpty ? pet.name : name.trim();
    notifyListeners();
  }

  void feed() {
    final pet = currentPet;
    if (pet == null) return;
    pet.hunger = (pet.hunger + 12).clamp(0, 100).toInt();
    pet.statusText = 'Full and happy';
    latestBubble = 'That was delicious. Thank you!';
    notifyListeners();
  }

  void clean() {
    final pet = currentPet;
    if (pet == null) return;
    pet.cleanliness = (pet.cleanliness + 10).clamp(0, 100).toInt();
    pet.statusText = 'Fresh and shiny';
    latestBubble = 'I feel sparkly now.';
    notifyListeners();
  }

  void caress() {
    final pet = currentPet;
    if (pet == null) return;
    pet.mood = (pet.mood + 10).clamp(0, 100).toInt();
    pet.statusText = 'Loved';
    latestBubble = 'That made my whole day.';
    notifyListeners();
  }

  void toggleChatMode() {
    chatMode = !chatMode;
    notifyListeners();
  }

  void sendMockMessage() {
    final replies = [
      'I am listening.',
      'Can we stay together a little longer?',
      'Today feels softer with you here.',
      'Tell me one tiny good thing from today.',
    ];
    latestBubble = replies[DateTime.now().millisecond % replies.length];
    final pet = currentPet;
    if (pet != null) {
      pet.mood = (pet.mood + 4).clamp(0, 100).toInt();
      pet.statusText = 'Chatting with you';
    }
    notifyListeners();
  }
}
