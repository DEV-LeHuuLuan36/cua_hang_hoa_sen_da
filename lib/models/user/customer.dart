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
    final now = DateTime.now().millisecondsSinceEpoch;
    return Customer(
      id: map[UserContract.colId] as String? ?? '',
      username: map[UserContract.colUsername] as String? ?? 'user',
      password: map[UserContract.colPassword] as String? ?? '',
      fullName: map[UserContract.colFullName] as String? ?? 'Khách hàng',
      email: map[UserContract.colEmail] as String? ?? '',
      phone: map[UserContract.colPhone] as String? ?? '',
      avatar: map[UserContract.colAvatar] as String?,
      membershipLevel: MembershipLevel.fromString(map[UserContract.colMembershipLevel] ?? 'BRONZE'),
      points: map[UserContract.colPoints] as int? ?? 0,
      totalSpent: (map[UserContract.colTotalSpent] as num?)?.toDouble() ?? 0.0,
      createdAt: map[UserContract.colCreatedAt] as int? ?? now,
      updatedAt: map[UserContract.colUpdatedAt] as int? ?? now,
      lastLogin: map[UserContract.colLastLogin] as int?,
    );
  }
}