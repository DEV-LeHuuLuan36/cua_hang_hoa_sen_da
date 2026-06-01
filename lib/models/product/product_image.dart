import '../../database/contracts/product_contract.dart';

class ProductImage {
  final String id;
  final String productId;
  final String imageUrl;
  final bool isPrimary;
  final int sortOrder;
  final int createdAt;

  ProductImage({
    required this.id,
    required this.productId,
    required this.imageUrl,
    this.isPrimary = false,
    this.sortOrder = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      ProductImageContract.colId: id,
      ProductImageContract.colProductId: productId,
      ProductImageContract.colImageUrl: imageUrl,
      ProductImageContract.colIsPrimary: isPrimary ? 1 : 0,
      ProductImageContract.colSortOrder: sortOrder,
      ProductImageContract.colCreatedAt: createdAt,
    };
  }

  factory ProductImage.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return ProductImage(
      id: map[ProductImageContract.colId] as String? ?? '',
      productId: map[ProductImageContract.colProductId] as String? ?? '',
      imageUrl: map[ProductImageContract.colImageUrl] as String? ?? '',
      isPrimary: map[ProductImageContract.colIsPrimary] == 1,
      sortOrder: map[ProductImageContract.colSortOrder] as int? ?? 0,
      createdAt: map[ProductImageContract.colCreatedAt] as int? ?? now,
    );
  }
}