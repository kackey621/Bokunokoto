class UserProfile {
  final String? realName;
  final String? relationship;
  final String? purposeOfAccess;
  final bool profileCompleted;
  final DateTime? profileCompletedAt;
  final bool faceVerified;
  final bool canAccessL2;

  UserProfile({
    this.realName,
    this.relationship,
    this.purposeOfAccess,
    this.profileCompleted = false,
    this.profileCompletedAt,
    this.faceVerified = false,
    this.canAccessL2 = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      realName: json['real_name'],
      relationship: json['relationship'],
      purposeOfAccess: json['purpose_of_access'],
      profileCompleted: json['profile_completed'] ?? false,
      profileCompletedAt: json['profile_completed_at'] != null
          ? DateTime.parse(json['profile_completed_at'])
          : null,
      faceVerified: json['face_verified'] ?? false,
      canAccessL2: json['can_access_l2'] ?? false,
    );
  }

  bool get isComplete => realName != null && relationship != null && purposeOfAccess != null;
}
