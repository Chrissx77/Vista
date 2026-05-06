class Profile {
  final String id;
  final String email;
  final String displayName;
  final String? createdAt;
  final bool isPremium;

  Profile({
    required this.id,
    required this.email,
    required this.displayName,
    this.createdAt,
    this.isPremium = false,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      isPremium: json['is_premium'] == true,
    );
  }
}
