enum OrderStatus {
  PENDING,
  CONFIRMED,
  PREPARING,
  SHIPPING,
  DELIVERED,
  CANCELLED;

  static OrderStatus fromString(String status) {
    return OrderStatus.values.firstWhere(
          (e) => e.name == status.toUpperCase(),
      orElse: () => OrderStatus.PENDING,
    );
  }
}