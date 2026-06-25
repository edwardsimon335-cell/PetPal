import 'package:flutter/material.dart';
import 'package:pixelarticons/pixelarticons.dart';

import '../../app/petpal_controller.dart';
import '../../core/theme/petpal_theme.dart';
import '../../shared/widgets/pixel_page_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({required this.controller, super.key});

  final PetPalController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final switches = <String, bool>{
    'Message Notifications': true,
    'Status Decay Reminders': true,
    'Daily Greeting': false,
    'Scene Time Sync': true,
    'Interaction SFX': true,
  };

  @override
  Widget build(BuildContext context) {
    final pet = widget.controller.currentPet;
    return PixelPageScaffold(
      useRoomBackground: false,
      overlay: const LinearGradient(
        colors: [Color(0xFF2C1E13), Color(0xFF1B130C)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 18,
                  top: 8,
                  child: IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Pixel.arrowleft, size: 20),
                    style: IconButton.styleFrom(
                      fixedSize: const Size(40, 40),
                      backgroundColor: PetPalColors.ink.withValues(alpha: 0.78),
                      foregroundColor: const Color(0xFFF3E4C4),
                      side: const BorderSide(color: Color(0x26F7E9CD)),
                      shape: const CircleBorder(),
                    ),
                  ),
                ),
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: Color(0xFFF3E4C4),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
              children: [
                const _SectionTitle('Home Widget'),
                Row(
                  children: [
                    Expanded(
                      child: _WidgetPreview(
                        title: pet?.name ?? 'Mochi',
                        subtitle: pet?.statusText ?? 'Feeling cozy',
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _WidgetPreview(
                        title: pet?.name ?? 'Mochi',
                        subtitle: 'Mood ${pet?.mood ?? 100}% - Misses you',
                        compact: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const _SettingsPanel(
                  children: [
                    _ActionRow(label: 'Add to Home Screen'),
                  ],
                ),
                const SizedBox(height: 20),
                const _SectionTitle('Notifications'),
                _SettingsPanel(
                  children: [
                    for (final entry in switches.entries.take(3))
                      _SwitchRow(
                        label: entry.key,
                        value: entry.value,
                        onChanged: (value) =>
                            setState(() => switches[entry.key] = value),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const _SectionTitle('Experience'),
                _SettingsPanel(
                  children: [
                    for (final entry in switches.entries.skip(3))
                      _SwitchRow(
                        label: entry.key,
                        value: entry.value,
                        onChanged: (value) =>
                            setState(() => switches[entry.key] = value),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const _SectionTitle('Storage'),
                const _SettingsPanel(
                  children: [
                    _ValueRow(label: 'Local Cache', value: '128 MB'),
                  ],
                ),
                const SizedBox(height: 20),
                const _SectionTitle('About'),
                const _SettingsPanel(
                  children: [
                    _ActionRow(label: 'Feedback'),
                    _ActionRow(label: 'Terms of Service'),
                    _ActionRow(label: 'Privacy Policy'),
                    _ActionRow(label: 'About PetPal'),
                  ],
                ),
                const SizedBox(height: 26),
                const Center(
                  child: Text(
                    'PetPal V1.0.0',
                    style: TextStyle(
                      color: Color(0xFF7D6648),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WidgetPreview extends StatelessWidget {
  const _WidgetPreview({
    required this.title,
    required this.subtitle,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 126,
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFF3E2B8), Color(0xFFE3C184)]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: compact
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Pixel.heart, color: PetPalColors.bark, size: 32),
                const SizedBox(height: 8),
                Text(title,
                    overflow: TextOverflow.ellipsis, style: _titleStyle),
                Text(subtitle,
                    overflow: TextOverflow.ellipsis, style: _subtitleStyle),
              ],
            )
          : Row(
              children: [
                const Icon(Pixel.heart, color: PetPalColors.bark, size: 42),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          overflow: TextOverflow.ellipsis, style: _titleStyle),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _subtitleStyle),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: const LinearProgressIndicator(
                          value: 0.72,
                          minHeight: 6,
                          backgroundColor: Color(0x335B4225),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(PetPalColors.heart),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  static const _titleStyle = TextStyle(
    color: PetPalColors.bark,
    fontWeight: FontWeight.w900,
    fontSize: 15,
    letterSpacing: 0,
  );

  static const _subtitleStyle = TextStyle(
    color: Color(0xFF8A6E44),
    fontWeight: FontWeight.w800,
    fontSize: 11,
    letterSpacing: 0,
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
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

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.children});

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

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  color: Color(0xFFEAD9BC),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: PetPalColors.honey,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  color: Color(0xFFEAD9BC),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0),
            ),
          ),
          const Icon(Pixel.chevronright, color: Color(0xFF8C7252)),
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  color: Color(0xFFEAD9BC),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
                color: Color(0xFFA98E6A),
                fontWeight: FontWeight.w800,
                letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}
