enum UserRole { customer, delivery }

UserRole userRoleFromString(String value) {
  return value == 'delivery' ? UserRole.delivery : UserRole.customer;
}

String userRoleToString(UserRole role) {
  return role == UserRole.delivery ? 'delivery' : 'customer';
}

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.isAvailable = true,
    this.isVerified = false,
    this.currentLat,
    this.currentLng,
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final bool isAvailable;
  final bool isVerified;
  final double? currentLat;
  final double? currentLng;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      role: userRoleFromString(json['role'] as String),
      isAvailable: json['is_available'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      currentLat: (json['current_lat'] as num?)?.toDouble(),
      currentLng: (json['current_lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': userRoleToString(role),
      };
}
