enum AddressType {
  HOME,
  OFFICE,
  OTHER;

  static AddressType fromString(String type) {
    return AddressType.values.firstWhere(
          (e) => e.name == type.toUpperCase(),
      orElse: () => AddressType.HOME,
    );
  }
}