enum MembershipLevel {
  BRONZE,
  SILVER,
  GOLD,
  PLATINUM;

  static MembershipLevel fromString(String level) {
    return MembershipLevel.values.firstWhere(
          (e) => e.name == level.toUpperCase(),
      orElse: () => MembershipLevel.BRONZE,
    );
  }
}