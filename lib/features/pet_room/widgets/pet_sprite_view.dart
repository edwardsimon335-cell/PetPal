import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_assets.dart';
import '../../../shared/models/pet_activity.dart';

/// One animation clip: a horizontal strip of square frames, plus which frames
/// to play (the [sequence]) and how long each is shown.
class PetSpriteClip {
  const PetSpriteClip({
    required this.asset,
    required this.sequence,
    required this.frameDuration,
  });

  final String asset;
  final List<int> sequence;
  final Duration frameDuration;
}

/// The full set of clips for one pet role, keyed by activity.
class PetSpriteSet {
  const PetSpriteSet({
    required this.frameSize,
    required this.clips,
    this.footBaseline = 0.9,
  });

  /// Side length in source pixels of one frame in every strip (square).
  final double frameSize;

  /// Where the pet's feet sit within a frame, as a fraction of [frameSize]
  /// from the top (e.g. 0.86 = feet ~110/128 down). Used to drop the ground
  /// shadow at the feet instead of the empty bottom of the frame.
  final double footBaseline;

  final Map<PetActivity, PetSpriteClip> clips;

  Set<String> get assets =>
      clips.values.map((clip) => clip.asset).toSet();

  PetSpriteClip clipFor(PetActivity activity) =>
      clips[activity] ?? clips[PetActivity.idle]!;
}

/// NuoNuo — the first role with hand-authored 128px frames. Sleep loops only
/// the steady breathing frames (1–2); the settle/wake frames in the strip are
/// reserved for future enter/exit transitions.
const PetSpriteSet _nuonuoSpriteSet = PetSpriteSet(
  frameSize: 128,
  footBaseline: 0.86, // feet rest ~110/128 down the frame
  clips: {
    PetActivity.idle: PetSpriteClip(
      asset: AppAssets.nuonuoIdle,
      sequence: [0, 1, 2, 3],
      frameDuration: Duration(milliseconds: 420),
    ),
    PetActivity.walking: PetSpriteClip(
      asset: AppAssets.nuonuoWalk,
      sequence: [0, 1, 2, 3],
      frameDuration: Duration(milliseconds: 160),
    ),
    PetActivity.sleeping: PetSpriteClip(
      asset: AppAssets.nuonuoSleep,
      sequence: [1, 2],
      frameDuration: Duration(milliseconds: 720),
    ),
    PetActivity.eating: PetSpriteClip(
      asset: AppAssets.nuonuoEat,
      sequence: [0, 1, 2],
      frameDuration: Duration(milliseconds: 180),
    ),
    PetActivity.happy: PetSpriteClip(
      asset: AppAssets.nuonuoHappy,
      sequence: [0, 1, 2],
      frameDuration: Duration(milliseconds: 130),
    ),
    PetActivity.attentive: PetSpriteClip(
      asset: AppAssets.nuonuoAttentive,
      sequence: [0, 1],
      frameDuration: Duration(milliseconds: 450),
    ),
  },
);

/// Returns the frame set for a role, or null if it has no authored frames yet
/// (those roles fall back to the single static image).
PetSpriteSet? petSpriteSetForRole(String roleId) {
  if (roleId == 'nuonuo') return _nuonuoSpriteSet;
  return null;
}

/// Plays a [PetSpriteSet] clip. The current frame is derived from
/// [elapsedInActivity] (seconds since the activity began), so this widget stays
/// in lockstep with the stage's ticker without owning a second one.
class PetSpriteView extends StatefulWidget {
  const PetSpriteView({
    required this.spriteSet,
    required this.activity,
    required this.elapsedInActivity,
    required this.size,
    super.key,
  });

  final PetSpriteSet spriteSet;
  final PetActivity activity;
  final double elapsedInActivity;
  final double size;

  @override
  State<PetSpriteView> createState() => _PetSpriteViewState();
}

class _PetSpriteViewState extends State<PetSpriteView> {
  final Map<String, ui.Image> _images = {};

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  @override
  void didUpdateWidget(covariant PetSpriteView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spriteSet != widget.spriteSet) {
      _images.clear();
      _loadAssets();
    }
  }

  Future<void> _loadAssets() async {
    for (final asset in widget.spriteSet.assets) {
      try {
        final data = await rootBundle.load(asset);
        final codec =
            await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        if (!mounted) return;
        setState(() => _images[asset] = frame.image);
      } catch (error) {
        debugPrint('PetSpriteView: failed to load $asset: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clip = widget.spriteSet.clipFor(widget.activity);
    final image = _images[clip.asset];
    if (image == null) {
      return SizedBox(width: widget.size, height: widget.size);
    }
    final step = widget.elapsedInActivity * 1000 / clip.frameDuration.inMilliseconds;
    final frameIndex = clip.sequence[step.floor() % clip.sequence.length];

    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: _FramePainter(
        image: image,
        frameIndex: frameIndex,
        frameSize: widget.spriteSet.frameSize,
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  _FramePainter({
    required this.image,
    required this.frameIndex,
    required this.frameSize,
  });

  final ui.Image image;
  final int frameIndex;
  final double frameSize;

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(frameIndex * frameSize, 0, frameSize, frameSize);
    final dst = Offset.zero & size;
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false,
    );
  }

  @override
  bool shouldRepaint(covariant _FramePainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.frameIndex != frameIndex;
  }
}
