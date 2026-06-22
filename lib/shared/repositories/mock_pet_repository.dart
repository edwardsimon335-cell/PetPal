import 'package:flutter/material.dart';

import '../models/preset_role.dart';

class MockPetRepository {
  const MockPetRepository();

  List<PresetRole> presetRoles() {
    return const [
      PresetRole(
        id: 'mochi',
        name: 'Mochi',
        species: 'Orange Cat',
        description: 'A playful little foodie with sunny tabby stripes.',
        defaultTraits: ['Playful', 'Foodie', 'Affectionate'],
        body: Color(0xFFEF9A3D),
        shade: Color(0xFFD3741A),
        eye: Color(0xFF7A4E1A),
        accent: Color(0xFFF6C79A),
        tabby: true,
      ),
      PresetRole(
        id: 'luna',
        name: 'Luna',
        species: 'Calico Cat',
        description: 'Soft, sassy, and very good at pretending not to care.',
        defaultTraits: ['Lazy', 'Sassy', 'Affectionate'],
        body: Color(0xFFE8C486),
        shade: Color(0xFF2F2B2A),
        eye: Color(0xFFF0C040),
        accent: Color(0xFFE0A0A0),
        chest: Color(0xFFF2ECE2),
      ),
      PresetRole(
        id: 'biscuit',
        name: 'Biscuit',
        species: 'Corgi',
        description:
            'A bright little dog who believes every sound is snack news.',
        defaultTraits: ['Playful', 'Chatty', 'Foodie'],
        body: Color(0xFFB5793F),
        shade: Color(0xFF86521F),
        eye: Color(0xFF542F16),
        accent: Color(0xFFCFA676),
        chest: Color(0xFFE8D2AC),
      ),
      PresetRole(
        id: 'shadow',
        name: 'Shadow',
        species: 'Black Cat',
        description: 'Cool, quiet, and secretly very attached.',
        defaultTraits: ['Cool', 'Sassy', 'Shy'],
        body: Color(0xFF3C372F),
        shade: Color(0xFF221D17),
        eye: Color(0xFFF4C430),
        accent: Color(0xFFC89A9A),
        chest: Color(0xFFF2ECE2),
      ),
      PresetRole(
        id: 'snowball',
        name: 'Snowball',
        species: 'White Rabbit',
        description: 'Gentle, shy, and fond of quiet mornings.',
        defaultTraits: ['Gentle', 'Shy', 'Affectionate'],
        body: Color(0xFFF4ECE0),
        shade: Color(0xFFDAC9B1),
        eye: Color(0xFF9A6B8A),
        accent: Color(0xFFF0BCBC),
      ),
      PresetRole(
        id: 'pebble',
        name: 'Pebble',
        species: 'Tiny Fantasy Pet',
        description: 'Curious, strange, and always ready to explore.',
        defaultTraits: ['Curious', 'Playful', 'Chatty'],
        body: Color(0xFF9A9CA0),
        shade: Color(0xFF65686C),
        eye: Color(0xFF3F6285),
        accent: Color(0xFFC2C4C6),
        chest: Color(0xFFE6E8EA),
        tabby: true,
      ),
    ];
  }

  PresetRole? roleById(String id) {
    for (final role in presetRoles()) {
      if (role.id == id) return role;
    }
    return null;
  }

  PresetRole uploadedPlaceholder(int variant) {
    final colors = [
      const Color(0xFFD18A4C),
      const Color(0xFFCF8748),
      const Color(0xFFC47A3C),
      const Color(0xFFD99A5C),
    ];
    final color = colors[variant % colors.length];
    return PresetRole(
      id: 'upload-$variant',
      name: 'Custom Pet',
      species: 'Generated Pixel Pet',
      description: 'A temporary generated avatar from the upload flow.',
      defaultTraits: const [],
      body: color,
      shade: Color.alphaBlend(Colors.black.withValues(alpha: 0.18), color),
      eye: const Color(0xFF241A12),
      accent: const Color(0xFFE09A9A),
      chest: const Color(0xFFF3E6C8),
    );
  }
}
