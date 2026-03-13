enum ProductStatus {
  AVAILABLE,
  OUT_OF_STOCK,
  HIDDEN;

  static ProductStatus fromString(String status) {
    return ProductStatus.values.firstWhere(
          (e) => e.name == status.toUpperCase(),
      orElse: () => ProductStatus.AVAILABLE,
    );
  }
}