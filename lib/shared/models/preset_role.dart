import 'package:flutter/material.dart';

class PresetRole {
  const PresetRole({
    required this.id,
    required this.name,
    required this.species,
    required this.description,
    required this.defaultTraits,
    required this.body,
    required this.shade,
    required this.eye,
    required this.accent,
    this.chest,
    this.tabby = false,
  });

  final String id;
  final String name;
  final String species;
  final String description;
  final List<String> defaultTraits;
  final Color body;
  final Color shade;
  final Color eye;
  final Color accent;
  final Color? chest;
  final bool tabby;
}
