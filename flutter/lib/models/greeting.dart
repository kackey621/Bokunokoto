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

  bool get isLocked => unlockedAt == null;
  bool get isReadyToUnlock => isLocked && scheduledDeliveryTime.isBefore(DateTime.now());
  Duration get timeUntilUnlock => scheduledDeliveryTime.difference(DateTime.now());

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
