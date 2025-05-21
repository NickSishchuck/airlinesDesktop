// lib/models/user.dart
class User {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? gender;

  User({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.gender,  //
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      role: json['role'],
      gender: json['gender'],  // Parse from JSON
    );
  }
}