import '../../database/contracts/user_contract.dart';
import '../enums/user_role.dart';
import '../enums/membership_level.dart';
import 'user.dart';

class Customer extends User {
  Customer({
    required String id,
    required String username,
    required String password,
    required String fullName,
    required String email,
    required String phone,
    String? avatar,
    MembershipLevel membershipLevel = MembershipLevel.BRONZE,
    int points = 0,
    double totalSpent = 0.0,
    required int createdAt,
    required int updatedAt,
    int? lastLogin,
  }) : super(
    id: id,
    username: username,
    password: password,
    fullName: fullName,
    email: email,
    phone: phone,
    avatar: avatar,
    role: UserRole.CUSTOMER, // Mặc định role là CUSTOMER
    membershipLevel: membershipLevel,
    points: points,
    totalSpent: totalSpent,
    createdAt: createdAt,
    updatedAt: updatedAt,
    lastLogin: lastLogin,
  );

  @override
  Map<String, dynamic> toMap() {
    return {
      UserContract.colId: id,
      UserContract.colUsername: username,
      UserContract.colPassword: password,
      UserContract.colFullName: fullName,
      UserContract.colEmail: email,
      UserContract.colPhone: phone,
      UserContract.colAvatar: avatar,
      UserContract.colRole: role.name,
      UserContract.colMembershipLevel: membershipLevel.name,
      UserContract.colPoints: points,
      UserContract.colTotalSpent: totalSpent,
      UserContract.colCreatedAt: createdAt,
      UserContract.colUpdatedAt: updatedAt,
      UserContract.colLastLogin: lastLogin,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map[UserContract.colId],
      username: map[UserContract.colUsername],
      password: map[UserContract.colPassword],
      fullName: map[UserContract.colFullName],
      email: map[UserContract.colEmail],
      phone: map[UserContract.colPhone],
      avatar: map[UserContract.colAvatar],
      // Convert text từ SQLite sang Enum
      membershipLevel: MembershipLevel.fromString(map[UserContract.colMembershipLevel] ?? 'BRONZE'),
      points: map[UserContract.colPoints] ?? 0,
      totalSpent: (map[UserContract.colTotalSpent] ?? 0.0).toDouble(),
      createdAt: map[UserContract.colCreatedAt],
      updatedAt: map[UserContract.colUpdatedAt],
      lastLogin: map[UserContract.colLastLogin],
    );
  }
}