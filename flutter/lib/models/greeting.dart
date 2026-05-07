class Greeting {
  final String id;
  final String content;
  final DateTime scheduledDeliveryTime;
  final DateTime? unlockedAt;
  final String unlockAnimationType;

  Greeting({
    required this.id,
    required this.content,
    required this.scheduledDeliveryTime,
    this.unlockedAt,
    required this.unlockAnimationType,
  });

  bool get locked => unlockedAt == null;
  bool get isLocked => unlockedAt == null;
  bool get isReadyToUnlock => isLocked && scheduledDeliveryTime.isBefore(DateTime.now());
  Duration get timeUntilUnlock => scheduledDeliveryTime.difference(DateTime.now());

  Greeting copyWith({
    String? id,
    String? content,
    DateTime? scheduledDeliveryTime,
    DateTime? unlockedAt,
    String? unlockAnimationType,
  }) {
    return Greeting(
      id: id ?? this.id,
      content: content ?? this.content,
      scheduledDeliveryTime: scheduledDeliveryTime ?? this.scheduledDeliveryTime,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      unlockAnimationType: unlockAnimationType ?? this.unlockAnimationType,
    );
  }

  factory Greeting.fromJson(Map<String, dynamic> json) {
    return Greeting(
      id: json['id']?.toString() ?? '',
      content: json['content'] ?? '',
      scheduledDeliveryTime: DateTime.parse(json['scheduled_delivery_time'] ?? DateTime.now().toString()),
      unlockedAt: json['unlocked_at'] != null ? DateTime.parse(json['unlocked_at']) : null,
      unlockAnimationType: json['unlock_animation_type'] ?? 'fade',
    );
  }
}
