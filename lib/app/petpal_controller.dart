import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shared/models/pet_profile.dart';
import '../shared/models/preset_role.dart';
import '../shared/repositories/mock_pet_repository.dart';

class PetPalController extends ChangeNotifier {
  PetPalController({MockPetRepository repository = const MockPetRepository()})
      : _repository = repository {
    roles = _repository.presetRoles();
  }

  static const _petStorageKey = 'petpal.current_pet.v1';

  final MockPetRepository _repository;

  late final List<PresetRole> roles;
  int? selectedAvatarVariant;
  PresetRole? selectedRole;
  PetProfile? currentPet;
  String? selectedUploadPhotoPath;
  String latestBubble = 'I missed you. Want to play?';
  bool chatMode = false;
  bool isReady = false;

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

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final rawPet = prefs.getString(_petStorageKey);
    if (rawPet != null) {
      final json = jsonDecode(rawPet) as Map<String, dynamic>;
      final variant = json['avatarVariant'] as int? ?? 0;
      final role = _roleForStoredPet(json, variant);
      currentPet = PetProfile.fromJson(json, role: role);
      if (currentPet?.sourceType == PetSourceType.presetRole) {
        selectedRole = role;
      } else {
        selectedAvatarVariant = variant;
        selectedUploadPhotoPath = currentPet?.sourcePhotoPath;
      }
      _applyOfflineDecay();
      latestBubble = _welcomeBackBubble();
      await _saveCurrentPet();
    }
    isReady = true;
    notifyListeners();
  }

  void selectGeneratedAvatar(int variant) {
    selectedAvatarVariant = variant;
    notifyListeners();
  }

  void clearGeneratedAvatarSelection() {
    selectedAvatarVariant = null;
    notifyListeners();
  }

  void setUploadPhotoPath(String path) {
    selectedUploadPhotoPath = path;
    notifyListeners();
  }

  void selectRole(PresetRole role) {
    selectedRole = role;
    notifyListeners();
  }

  void createUploadedPet({
    required String name,
    required List<String> traits,
    String specialPersonalityDetail = '',
  }) {
    final variant = selectedAvatarVariant ?? 0;
    currentPet = PetProfile(
      name: name.trim().isEmpty ? 'Mochi' : name.trim(),
      sourceType: PetSourceType.uploadedPhoto,
      traits: traits,
      role: uploadedPlaceholder(variant),
      specialPersonalityDetail: specialPersonalityDetail.trim(),
      sourcePhotoPath: selectedUploadPhotoPath,
      avatarVariant: variant,
      generationStatus: 'generating',
      statusText: 'Generating final avatar',
    );
    latestBubble = 'What should we do first?';
    _saveCurrentPet();
    notifyListeners();
  }

  void createPresetPet({
    required String name,
    required List<String> traits,
    String specialPersonalityDetail = '',
  }) {
    final role = selectedRole ?? roles.first;
    currentPet = PetProfile(
      name: name.trim().isEmpty ? role.name : name.trim(),
      sourceType: PetSourceType.presetRole,
      traits: traits.isEmpty ? role.defaultTraits : traits,
      role: role,
      specialPersonalityDetail: specialPersonalityDetail.trim(),
      generationStatus: 'none',
      statusText: 'Feeling cozy',
    );
    latestBubble = 'I am home!';
    _saveCurrentPet();
    notifyListeners();
  }

  void updateName(String name) {
    final pet = currentPet;
    if (pet == null) return;
    pet.name = name.trim().isEmpty ? pet.name : name.trim();
    _touch(pet);
    _saveCurrentPet();
    notifyListeners();
  }

  void feed() {
    final pet = currentPet;
    if (pet == null) return;
    pet.hunger = (pet.hunger + 12).clamp(0, 100).toInt();
    pet.statusText = 'Full and happy';
    latestBubble = 'That was delicious. Thank you!';
    _touch(pet);
    _saveCurrentPet();
    notifyListeners();
  }

  void clean() {
    final pet = currentPet;
    if (pet == null) return;
    pet.cleanliness = (pet.cleanliness + 10).clamp(0, 100).toInt();
    pet.statusText = 'Fresh and shiny';
    latestBubble = 'I feel sparkly now.';
    _touch(pet);
    _saveCurrentPet();
    notifyListeners();
  }

  void caress() {
    final pet = currentPet;
    if (pet == null) return;
    pet.mood = (pet.mood + 10).clamp(0, 100).toInt();
    pet.statusText = 'Loved';
    latestBubble = 'That made my whole day.';
    _touch(pet);
    _saveCurrentPet();
    notifyListeners();
  }

  void toggleChatMode() {
    chatMode = !chatMode;
    notifyListeners();
  }

  void sendMockMessage(String message) {
    final text = message.trim();
    if (text.isEmpty) return;
    final pet = currentPet;
    if (pet != null) {
      pet.mood = (pet.mood + 4).clamp(0, 100).toInt();
      pet.statusText = 'Chatting with you';
      _touch(pet);
    }
    latestBubble = _mockReplyFor(text);
    _saveCurrentPet();
    notifyListeners();
  }

  PresetRole _roleForStoredPet(Map<String, dynamic> json, int variant) {
    final roleId = json['roleId'] as String? ?? '';
    if (roleId.startsWith('upload-') ||
        json['sourceType'] == PetSourceType.uploadedPhoto.name) {
      return uploadedPlaceholder(variant);
    }
    return _repository.roleById(roleId) ?? roles.first;
  }

  void _applyOfflineDecay() {
    final pet = currentPet;
    if (pet == null) return;

    final now = DateTime.now();
    final elapsed = now.difference(pet.lastActiveAt);
    final moodDrops = elapsed.inHours ~/ 4;
    final hungerDrops = elapsed.inHours ~/ 6;
    final cleanDrops = elapsed.inHours ~/ 8;

    pet.mood = (pet.mood - moodDrops * 10).clamp(0, 100).toInt();
    pet.hunger = (pet.hunger - hungerDrops * 15).clamp(0, 100).toInt();
    pet.cleanliness = (pet.cleanliness - cleanDrops * 10).clamp(0, 100).toInt();
    pet.lastActiveAt = now;
    pet.statusText = _statusTextFor(pet);
  }

  String _statusTextFor(PetProfile pet) {
    if (pet.hunger < 35) return 'A little hungry';
    if (pet.cleanliness < 35) return 'Needs a bath';
    if (pet.mood < 35) return 'Needs cuddles';
    if (pet.generationStatus == 'generating') return 'Generating final avatar';
    return 'Feeling cozy';
  }

  String _welcomeBackBubble() {
    final pet = currentPet;
    if (pet == null) return 'I missed you. Want to play?';
    if (pet.hunger < 35) return 'I saved you a tiny hungry face.';
    if (pet.cleanliness < 35) return 'Could we freshen up a little?';
    if (pet.mood < 35) return 'I missed you more than usual today.';
    return 'Welcome back. I kept your spot warm.';
  }

  String _mockReplyFor(String message) {
    final pet = currentPet;
    final traits = pet?.traits.join(', ') ?? 'sweet';
    if (message.endsWith('?')) {
      return 'I think yes. My $traits heart says we should try.';
    }
    if (message.toLowerCase().contains('sad') ||
        message.toLowerCase().contains('tired')) {
      return 'Come closer. We can make today smaller and softer.';
    }
    if (pet?.specialPersonalityDetail.isNotEmpty ?? false) {
      return '${pet!.specialPersonalityDetail} Also, I heard every word.';
    }
    return 'I heard you. Tell me one more tiny thing.';
  }

  void _touch(PetProfile pet) {
    pet.lastActiveAt = DateTime.now();
  }

  Future<void> _saveCurrentPet() async {
    final pet = currentPet;
    if (pet == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_petStorageKey, jsonEncode(pet.toJson()));
  }
}
