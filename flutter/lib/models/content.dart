class Content {
  final String id;
  final String title;
  final String body;
  final String format; // markdown, html, text
  final int requiredLevel;
  final String? symbolType;
  final bool? isAntigravityEnabled;
  final List<String>? permittedUserIds;

  Content({
    required this.id,
    required this.title,
    required this.body,
    required this.format,
    required this.requiredLevel,
    this.symbolType,
    this.isAntigravityEnabled,
    this.permittedUserIds,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      format: json['format'] ?? 'markdown',
      requiredLevel: json['required_level'] ?? 0,
      symbolType: json['symbol_type'],
      isAntigravityEnabled: json['is_antigravity_enabled'],
      permittedUserIds: List<String>.from(json['permitted_user_ids'] ?? []),
    );
  }

  bool get requiresLogin => requiredLevel >= 1;
  bool get requiresProfile => requiredLevel >= 2;
  bool get isHighSensitivity => requiredLevel >= 7;

  String get levelDisplay {
    final levels = ['Public', 'L1', 'L2', 'L3', 'L4', 'L5', 'L6', 'L7+'];
    return levels[requiredLevel.clamp(0, levels.length - 1)];
  }
}
