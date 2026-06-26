import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../app/petpal_controller.dart';
import '../../../core/theme/petpal_theme.dart';
import '../../../shared/models/pet_activity.dart';
import '../../../shared/widgets/pet_avatar_view.dart';
import 'pet_speech_bubble.dart';
import 'pet_sprite_view.dart';

/// The pet's living stage: the pet wanders within a floor band, naps on its
/// own, reacts to taps, and walks to center when chatting. Its speech bubble
/// follows it. Runs its own ticker so only this subtree repaints per frame.
///
/// Rendering uses the single static pet image for every activity today; the
/// movement is real (positional). Drawn pose/step frames plug in later via the
/// [PetActivity] passed to [_PetBody].
class PetStage extends StatefulWidget {
  const PetStage({required this.controller, super.key});

  final PetPalController controller;

  @override
  State<PetStage> createState() => _PetStageState();
}

class _PetStageState extends State<PetStage>
    with SingleTickerProviderStateMixin {
  static const double _petSize = 176;
  // Horizontal walkable band as a fraction of width (kept off the edges).
  static const double _bandLeft = 0.20;
  static const double _bandRight = 0.80;
  // Vertical band for the feet baseline (px from the stage bottom). Larger =
  // further back / higher on screen. The far edge is also capped by height so
  // the pet never climbs above the nightstand.
  static const double _floorNear = 120;
  static const double _floorFar = 270;
  // Where the pet stands while chatting (center, slightly forward).
  static const double _chatX = 0.5;
  static const double _chatY = 0.35;

  late final Ticker _ticker;
  final math.Random _rand = math.Random();

  PetActivity _activity = PetActivity.idle;

  /// Pet position as fractions (0..1) of the walkable band (x) and depth (y).
  double _x = 0.5;
  double _y = 0.45;
  double _targetX = 0.5;
  double _targetY = 0.45;

  /// Accumulated seconds, used to derive bob/hop offsets.
  double _clock = 0;
  Duration _lastElapsed = Duration.zero;

  /// The [_clock] value when the current activity began — drives frame timing.
  double _activityStartClock = 0;

  DateTime _nextDecisionAt = DateTime.now();
  DateTime _sleepUntil = DateTime.now();
  DateTime _eventEndAt = DateTime.now();
  // After an autonomous wake or a tap, hold off napping for a bit so the pet
  // actually does something before dozing again (旅行青蛙-style autonomy).
  DateTime _napCooldownUntil = DateTime.now();

  int _lastSeenActionSeq = 0;

  PetBehaviorProfile get _profile => PetBehaviorProfile.forSpecies(
        widget.controller.currentPet?.role.species ?? '',
      );

  @override
  void initState() {
    super.initState();
    _lastSeenActionSeq = widget.controller.actionRequestSeq;
    widget.controller.addListener(_onController);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    widget.controller.removeListener(_onController);
    super.dispose();
  }

  void _onController() {
    // Pick up Feed/Clean/Pet button actions as one-shot reaction animations.
    final seq = widget.controller.actionRequestSeq;
    if (seq != _lastSeenActionSeq) {
      _lastSeenActionSeq = seq;
      final requested = widget.controller.requestedActivity;
      if (requested == PetActivity.eating || requested == PetActivity.happy) {
        _startEvent(requested);
      }
    }
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    if (dt <= 0) return;
    _clock += dt;
    final now = DateTime.now();

    // A timed reaction (eating/happy) always runs to completion first.
    if (_activity == PetActivity.eating || _activity == PetActivity.happy) {
      if (now.isAfter(_eventEndAt)) _toIdle(now);
    } else if (widget.controller.chatMode) {
      _tickChat(now);
    } else {
      _tickFree(now);
    }

    if (_activity == PetActivity.walking) _moveToward(dt, now);

    if (mounted) setState(() {});
  }

  void _tickChat(DateTime now) {
    // In chat mode the pet gathers at center and faces the user.
    switch (_activity) {
      case PetActivity.idle:
      case PetActivity.sleeping:
        _startWalk(_chatX, _chatY);
        break;
      case PetActivity.walking:
        _targetX = _chatX;
        _targetY = _chatY;
        break;
      case PetActivity.attentive:
      case PetActivity.eating:
      case PetActivity.happy:
        break;
    }
  }

  void _tickFree(DateTime now) {
    switch (_activity) {
      case PetActivity.attentive:
        // Just left chat mode — rejoin normal life.
        _toIdle(now);
        break;
      case PetActivity.sleeping:
        if (now.isAfter(_sleepUntil)) {
          // Wake on its own, then stay up for a while.
          _napCooldownUntil = now.add(const Duration(seconds: 15));
          _toIdle(now);
        }
        break;
      case PetActivity.idle:
        if (now.isAfter(_nextDecisionAt)) _decide(now);
        break;
      case PetActivity.walking:
      case PetActivity.eating:
      case PetActivity.happy:
        break;
    }
  }

  void _decide(DateTime now) {
    final sinceInteraction = now.difference(widget.controller.lastInteractionAt);
    if (sinceInteraction >= _profile.idleBeforeNap &&
        now.isAfter(_napCooldownUntil)) {
      _enter(PetActivity.sleeping);
      _sleepUntil = now.add(_profile.napDuration);
      return;
    }
    if (_rand.nextDouble() < _profile.moveProbability) {
      _startWalk(_rand.nextDouble(), _rand.nextDouble());
    } else {
      _nextDecisionAt = now.add(_randomPause());
    }
  }

  /// Switches activity and resets the frame clock (only on a real change, so
  /// re-targeting a walk doesn't restart its gait cycle).
  void _enter(PetActivity activity) {
    if (_activity == activity) return;
    _activity = activity;
    _activityStartClock = _clock;
  }

  void _startWalk(double targetX, double targetY) {
    _targetX = targetX.clamp(0.0, 1.0);
    _targetY = targetY.clamp(0.0, 1.0);
    _enter(PetActivity.walking);
  }

  void _moveToward(double dt, DateTime now) {
    final stepX = _profile.walkSpeed * dt;
    final stepY = stepX * 0.6; // depth shifts are gentler than strolling
    final dx = _targetX - _x;
    final dy = _targetY - _y;
    final reachedX = dx.abs() <= stepX;
    final reachedY = dy.abs() <= stepY;
    if (reachedX && reachedY) {
      _x = _targetX;
      _y = _targetY;
      if (widget.controller.chatMode) {
        _enter(PetActivity.attentive);
      } else {
        _toIdle(now);
      }
      return;
    }
    _x = reachedX ? _targetX : _x + stepX * dx.sign;
    _y = reachedY ? _targetY : _y + stepY * dy.sign;
  }

  void _toIdle(DateTime now) {
    _enter(PetActivity.idle);
    _nextDecisionAt = now.add(_randomPause());
  }

  void _startEvent(PetActivity activity) {
    final now = DateTime.now();
    _enter(activity);
    _eventEndAt = now.add(activity == PetActivity.eating
        ? const Duration(milliseconds: 2000)
        : const Duration(milliseconds: 1500));
    _napCooldownUntil = now.add(const Duration(seconds: 12));
  }

  Duration _randomPause() {
    final min = _profile.minPause.inMilliseconds;
    final max = _profile.maxPause.inMilliseconds;
    return Duration(milliseconds: min + _rand.nextInt(math.max(1, max - min)));
  }

  void _onTapPet() {
    final now = DateTime.now();
    final wasSleeping = _activity == PetActivity.sleeping;
    widget.controller.pokePet(); // reaction line + marks interaction
    _napCooldownUntil = now.add(const Duration(seconds: 12));
    if (wasSleeping) {
      _toIdle(now); // wake gently, no hop
    } else if (!widget.controller.chatMode) {
      _startEvent(PetActivity.happy);
    } else {
      _startEvent(PetActivity.happy); // a quick wiggle, returns to attentive
    }
    setState(() {});
  }

  double get _hop {
    switch (_activity) {
      case PetActivity.happy:
        return math.sin(_clock * 9).abs() * 16;
      case PetActivity.eating:
        return math.sin(_clock * 6).abs() * 5;
      case PetActivity.walking:
        return math.sin(_clock * 7).abs() * 3; // subtle, so it's not a slide
      case PetActivity.idle:
      case PetActivity.sleeping:
      case PetActivity.attentive:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.controller.currentPet;
    if (pet == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final hop = _hop;
        final spriteSet = petSpriteSetForRole(pet.role.id);

        final bandLeftPx = width * _bandLeft;
        final bandRightPx = width * _bandRight;
        final centerX = bandLeftPx + _x * (bandRightPx - bandLeftPx);

        // Depth: further back (_y→1) sits higher and renders a touch smaller.
        final floorFar = math.min(_floorFar, height * 0.34);
        final floorBottom = _floorNear + _y * (floorFar - _floorNear);
        final depthScale = 1.0 - 0.16 * _y;

        // Authored frames are square; the fallback static art is slightly tall.
        final spriteHeight = (spriteSet != null ? _petSize : _petSize * 1.16);
        final footBaseline = spriteSet?.footBaseline ?? 1.0;
        // Empty space below the feet inside the frame, after depth scaling.
        final footGap = _petSize * (1 - footBaseline) * depthScale;
        // Box bottom so the drawn feet land exactly on the floor line.
        final petBottom = floorBottom - footGap;
        // Top of the scaled art, where the bubble / Zzz should hover above.
        final headTop = petBottom + spriteHeight * depthScale;
        final sleeping = _activity == PetActivity.sleeping;
        final shadowWidth = _petSize * 0.5 * depthScale;

        return Stack(
          children: [
            // Ground shadow, anchored at the feet (shrinks as the pet hops up).
            Positioned(
              bottom: floorBottom - 7,
              left: centerX - shadowWidth / 2,
              child: Opacity(
                opacity: 0.22,
                child: Container(
                  width: shadowWidth,
                  height: 13,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  transform: Matrix4.diagonal3Values(
                    1 - (hop / 60).clamp(0.0, 0.45),
                    1,
                    1,
                  ),
                  transformAlignment: Alignment.center,
                ),
              ),
            ),

            // The pet itself (animated frames when authored, else static art).
            Positioned(
              bottom: petBottom + hop,
              left: centerX - _petSize / 2,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onTapPet,
                child: Transform.scale(
                  scale: depthScale,
                  alignment: Alignment.bottomCenter,
                  child: spriteSet != null
                      ? PetSpriteView(
                          spriteSet: spriteSet,
                          activity: _activity,
                          elapsedInActivity: _clock - _activityStartClock,
                          size: _petSize,
                        )
                      : PetAvatarView(
                          role: pet.role,
                          imageUrl: pet.avatarUrl,
                          variant: pet.avatarVariant,
                          size: _petSize,
                        ),
                ),
              ),
            ),

            // Sleeping "Zzz", else the speech bubble — both follow the pet.
            if (sleeping)
              Positioned(
                bottom: headTop - 6,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment(_alignX(centerX, width), 0),
                    child: _ZzzMark(clock: _clock),
                  ),
                ),
              )
            else
              Positioned(
                bottom: headTop + 4,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment(_alignX(centerX, width), 0),
                    child: PetSpeechBubble(
                      controller: widget.controller,
                      animated: widget.controller.chatMode,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Maps a pixel x into an [Alignment] x (-1..1) so a hug-content child is
  /// centered over the pet but auto-clamped to stay fully on screen.
  double _alignX(double centerX, double width) {
    if (width <= 0) return 0;
    return (centerX / width * 2 - 1).clamp(-1.0, 1.0);
  }
}

class _ZzzMark extends StatelessWidget {
  const _ZzzMark({required this.clock});

  final double clock;

  @override
  Widget build(BuildContext context) {
    final float = math.sin(clock * 2) * 3;
    return Transform.translate(
      offset: Offset(0, float),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFAF0).withValues(alpha: 0.9),
          border: Border.all(color: PetPalColors.line, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'Z z z',
          style: TextStyle(
            color: Color(0xFF8C7A5E),
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
