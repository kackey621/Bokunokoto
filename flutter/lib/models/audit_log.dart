class AuditLogEntry {
  final String id;
  final String action;
  final DateTime? occurredAt;
  final String? userDisplayName;
  final String? contentTitle;
  final String? ipAddress;

  AuditLogEntry({
    required this.id,
    required this.action,
    this.occurredAt,
    this.userDisplayName,
    this.contentTitle,
    this.ipAddress,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map?;
    final content = json['content'] as Map?;
    return AuditLogEntry(
      id: json['id'].toString(),
      action: json['action'] as String? ?? 'unknown',
      occurredAt: json['occurred_at'] != null
          ? DateTime.tryParse(json['occurred_at'].toString())
          : null,
      userDisplayName: user?['display_name'] as String?,
      contentTitle: content?['title'] as String?,
      ipAddress: json['ip_address'] as String?,
    );
  }
}
