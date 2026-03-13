class UserContract {
  static const String tableName = 'users';

  static const String colId = 'id';
  static const String colUsername = 'username';
  static const String colPassword = 'password';
  static const String colFullName = 'full_name';
  static const String colEmail = 'email';
  static const String colPhone = 'phone';
  static const String colAvatar = 'avatar';
  static const String colRole = 'role';

  // Các trường tích hợp từ bảng memberships
  static const String colMembershipLevel = 'membership_level';
  static const String colPoints = 'points';
  static const String colTotalSpent = 'total_spent';

  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';
  static const String colLastLogin = 'last_login';
}