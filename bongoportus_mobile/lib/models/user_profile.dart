class UserProfile {
  final String id;
  final String email;
  final String role; // 'admin' | 'seller' | 'user'
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final bool isVerified;
  final bool isBlocked;
  final String? createdAt;

  UserProfile({
    required this.id,
    required this.email,
    this.role = 'user',
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.isVerified = false,
    this.isBlocked = false,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      fullName: json['full_name'],
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      isVerified: json['is_verified'] ?? false,
      isBlocked: json['is_blocked'] ?? false,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'is_verified': isVerified,
      'is_blocked': isBlocked,
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isSeller => role == 'seller';
  bool get isUser => role == 'user';

  String get displayName => fullName ?? email.split('@').first;

  UserProfile copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? role,
  }) {
    return UserProfile(
      id: id,
      email: email,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified,
      isBlocked: isBlocked,
      createdAt: createdAt,
    );
  }
}
