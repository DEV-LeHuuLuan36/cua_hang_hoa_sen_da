enum UserRole {
  ADMIN,
  CUSTOMER;

  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
          (e) => e.name == role.toUpperCase(),
      orElse: () => UserRole.CUSTOMER,
    );
  }
}