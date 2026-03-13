enum PaymentStatus {
  UNPAID,
  PAID,
  REFUNDED;

  static PaymentStatus fromString(String status) {
    return PaymentStatus.values.firstWhere(
          (e) => e.name == status.toUpperCase(),
      orElse: () => PaymentStatus.UNPAID,
    );
  }
}