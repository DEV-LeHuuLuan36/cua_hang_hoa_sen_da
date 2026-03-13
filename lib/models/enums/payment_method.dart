enum PaymentMethod {
  COD,
  BANKING,
  E_WALLET;

  static PaymentMethod fromString(String method) {
    return PaymentMethod.values.firstWhere(
          (e) => e.name == method.toUpperCase(),
      orElse: () => PaymentMethod.COD,
    );
  }
}