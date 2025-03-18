class UserModel {
  final String id;
  final String email;
  final String role;
  final bool isVerified;
  final String token;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.isVerified,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      isVerified: json['isVerified'] ?? false,
      token: json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'isVerified': isVerified,
      'token': token,
    };
  }
}
