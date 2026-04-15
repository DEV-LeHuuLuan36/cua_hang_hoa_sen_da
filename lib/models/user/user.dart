import '../../database/contracts/user_contract.dart';
import '../enums/user_role.dart';
import '../enums/membership_level.dart';

abstract class User {
  final String id;
  final String username;
  String password;
  final String fullName;
  final String email;
  final String phone;
  final String? avatar;
  final UserRole role;
  final MembershipLevel membershipLevel;
  final int points;
  final double totalSpent;
  final int createdAt;
  final int updatedAt;
  final int? lastLogin;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.fullName,
    required this.email,
    required this.phone,
    this.avatar,
    required this.role,
    this.membershipLevel = MembershipLevel.BRONZE,
    this.points = 0,
    this.totalSpent = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.lastLogin,
  });

  // Ép buộc các class con phải triển khai hàm toMap
  Map<String, dynamic> toMap();
}