/// Who authored a chat line.
enum ChatRole { user, pet }

/// Delivery state of a user message (pet messages are always [sent]).
///
/// Mirrors the single-round dialogue flow in the V1.1 spec: a user message is
/// shown immediately as [sending], then resolves to [sent] once the pet has
/// replied, or [failed] (with tap-to-retry) if the round could not complete.
enum ChatStatus { sending, sent, failed }

/// A single line in the conversation between the user and their pet.
///
/// Both the lightweight dialogue overlay on the main screen and the full chat
/// history window read from the same list of [ChatMessage]s, so the two views
/// stay in sync (see spec 3.4 — the window is a complete view of the same
/// conversation, not a separate chat page).
class ChatMessage {
  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.status = ChatStatus.sent,
    this.remembered = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ChatMessage.user(String text) {
    return ChatMessage(
      id: _newId(),
      role: ChatRole.user,
      text: text,
      status: ChatStatus.sending,
    );
  }

  factory ChatMessage.pet(String text) {
    return ChatMessage(
      id: _newId(),
      role: ChatRole.pet,
      text: text,
      status: ChatStatus.sent,
    );
  }

  final String id;
  final ChatRole role;
  String text;
  ChatStatus status;

  /// Whether the user long-pressed this line to "let the pet remember it"
  /// (spec 3.4, optional). Persisted so the marker survives restarts.
  bool remembered;
  final DateTime createdAt;

  bool get isUser => role == ChatRole.user;
  bool get isPet => role == ChatRole.pet;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'text': text,
      'status': status.name,
      'remembered': remembered,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final roleName = json['role'] as String? ?? ChatRole.pet.name;
    final statusName = json['status'] as String? ?? ChatStatus.sent.name;
    var status = ChatStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => ChatStatus.sent,
    );
    // A message persisted mid-flight is no longer in flight on restore, so a
    // dangling "sending" becomes "failed" (the user can tap to retry it).
    if (status == ChatStatus.sending) status = ChatStatus.failed;
    return ChatMessage(
      id: json['id'] as String? ?? _newId(),
      role: ChatRole.values.firstWhere(
        (value) => value.name == roleName,
        orElse: () => ChatRole.pet,
      ),
      text: json['text'] as String? ?? '',
      status: status,
      remembered: json['remembered'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }

  static int _counter = 0;
  static String _newId() {
    _counter += 1;
    return '${DateTime.now().microsecondsSinceEpoch}-$_counter';
  }
}
