/// What the pet is currently *doing* on the stage. This is separate from the
/// numeric status (mood/hunger/cleanliness): those describe how it feels, this
/// describes its current behavior/pose.
///
/// Rendering note: today every activity is drawn with the same single static
/// image. The enum is the seam where per-activity frame sequences will plug in
/// once the artwork exists (V1 spec: built-in roles get 2–4 frame animations).
enum PetActivity {
  /// Standing still on the floor.
  idle,

  /// Walking toward a target spot within the floor band.
  walking,

  /// Napping. Entered autonomously after inactivity; exits on its own after a
  /// species-dependent duration, or when the user taps the pet.
  sleeping,

  /// Playing the eating reaction after a Feed.
  eating,

  /// Playing a happy reaction after a caress/clean or a tap.
  happy,

  /// Chat mode: standing at center, facing the user, wandering paused.
  attentive,
}

/// Per-species tuning for how the pet moves and rests. Lets a cat laze around
/// and nap long while a dog roams more and naps briefly.
class PetBehaviorProfile {
  const PetBehaviorProfile({
    required this.walkSpeed,
    required this.minPause,
    required this.maxPause,
    required this.idleBeforeNap,
    required this.napDuration,
    required this.moveProbability,
  });

  /// Horizontal speed as a fraction of the walkable band width, per second.
  final double walkSpeed;

  /// Range of idle dwell time between wander moves.
  final Duration minPause;
  final Duration maxPause;

  /// How long the pet must be left alone (no interaction) before it naps.
  final Duration idleBeforeNap;

  /// How long a nap lasts before the pet wakes on its own.
  final Duration napDuration;

  /// Chance, at each idle decision point, of walking somewhere new vs. lingering.
  final double moveProbability;

  static PetBehaviorProfile forSpecies(String species) {
    final s = species.toLowerCase();
    if (s.contains('dog')) {
      // Energetic: roams often and fast, naps rarely and briefly.
      return const PetBehaviorProfile(
        walkSpeed: 0.20,
        minPause: Duration(milliseconds: 1200),
        maxPause: Duration(seconds: 3),
        idleBeforeNap: Duration(minutes: 5),
        napDuration: Duration(seconds: 12),
        moveProbability: 0.8,
      );
    }
    if (s.contains('rabbit') || s.contains('bunny')) {
      // Quick, frequent little moves; medium naps.
      return const PetBehaviorProfile(
        walkSpeed: 0.24,
        minPause: Duration(milliseconds: 900),
        maxPause: Duration(milliseconds: 2600),
        idleBeforeNap: Duration(minutes: 5),
        napDuration: Duration(seconds: 16),
        moveProbability: 0.75,
      );
    }
    if (s.contains('cat')) {
      // Lazy: strolls slowly, naps soon and long.
      return const PetBehaviorProfile(
        walkSpeed: 0.11,
        minPause: Duration(seconds: 3),
        maxPause: Duration(seconds: 7),
        idleBeforeNap: Duration(minutes: 5),
        napDuration: Duration(seconds: 25),
        moveProbability: 0.55,
      );
    }
    // Default / uploaded pets: balanced.
    return const PetBehaviorProfile(
      walkSpeed: 0.14,
      minPause: Duration(seconds: 2),
      maxPause: Duration(seconds: 5),
      idleBeforeNap: Duration(minutes: 5),
      napDuration: Duration(seconds: 18),
      moveProbability: 0.65,
    );
  }
}
