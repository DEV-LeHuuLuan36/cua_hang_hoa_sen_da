import '../../database/contracts/user_contract.dart';
import '../enums/user_role.dart';
import '../enums/membership_level.dart';
import 'user.dart';

class Admin extends User {
  Admin({
    required String id,
    required String username,
    required String password,
    required String fullName,
    required String email,
    required String phone,
    String? avatar,
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
    role: UserRole.ADMIN, // Mặc định role là ADMIN
    membershipLevel: MembershipLevel.BRONZE, // Admin không cần hạng thành viên
    points: 0,
    totalSpent: 0.0,
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

  factory Admin.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Admin(
      id: map[UserContract.colId] as String? ?? '',
      username: map[UserContract.colUsername] as String? ?? 'admin',
      password: map[UserContract.colPassword] as String? ?? '',
      fullName: map[UserContract.colFullName] as String? ?? 'Admin',
      email: map[UserContract.colEmail] as String? ?? 'admin@gmail.com',
      phone: map[UserContract.colPhone] as String? ?? '',
      avatar: map[UserContract.colAvatar] as String?,
      createdAt: map[UserContract.colCreatedAt] as int? ?? now,
      updatedAt: map[UserContract.colUpdatedAt] as int? ?? now,
      lastLogin: map[UserContract.colLastLogin] as int?,
    );
  }
}