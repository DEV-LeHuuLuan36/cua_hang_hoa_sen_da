import '../../database/contracts/product_contract.dart';
import '../enums/product_status.dart';
import 'care_instruction.dart';

class Succulent {
  final String id;
  final String categoryId;
  final String name;
  final String? scientificName;
  final String? description;
  final double price;
  final double? salePrice;
  final int stock;
  final String? sku;
  final ProductStatus status;
  final String? size;
  final String? color;
  final String? origin;
  final CareInstruction careInstruction;
  final bool isBestseller;
  final bool isNew;
  final double rating;
  final int reviewCount;
  final int views;
  final int createdAt;
  final int updatedAt;
  final String? primaryImage;

  Succulent({
    required this.id,
    required this.categoryId,
    required this.name,
    this.scientificName,
    this.description,
    required this.price,
    this.salePrice,
    this.stock = 0,
    this.sku,
    this.status = ProductStatus.AVAILABLE,
    this.size,
    this.color,
    this.origin,
    required this.careInstruction,
    this.isBestseller = false,
    this.isNew = true,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.views = 0,
    required this.createdAt,
    required this.updatedAt,
    this.primaryImage,
  });

  Map<String, dynamic> toMap() {
    // Ép kiểu boolean sang 0/1 cho SQLite
    final map = {
      ProductContract.colId: id,
      ProductContract.colCategoryId: categoryId,
      ProductContract.colName: name,
      ProductContract.colScientificName: scientificName,
      ProductContract.colDescription: description,
      ProductContract.colPrice: price,
      ProductContract.colSalePrice: salePrice,
      ProductContract.colStock: stock,
      ProductContract.colSku: sku,
      ProductContract.colStatus: status.name,
      ProductContract.colSize: size,
      ProductContract.colColor: color,
      ProductContract.colOrigin: origin,
      ProductContract.colIsBestseller: isBestseller ? 1 : 0,
      ProductContract.colIsNew: isNew ? 1 : 0,
      ProductContract.colRating: rating,
      ProductContract.colReviewCount: reviewCount,
      ProductContract.colViews: views,
      ProductContract.colCreatedAt: createdAt,
      ProductContract.colUpdatedAt: updatedAt,
    };

    // Gộp các trường của CareInstruction vào cùng Map
    map.addAll(careInstruction.toMap());
    return map;
  }

  factory Succulent.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Succulent(
      id: map[ProductContract.colId] as String? ?? '',
      categoryId: map[ProductContract.colCategoryId] as String? ?? '',
      name: map[ProductContract.colName] as String? ?? 'Sản phẩm',
      scientificName: map[ProductContract.colScientificName] as String?,
      description: map[ProductContract.colDescription] as String?,
      price: (map[ProductContract.colPrice] as num?)?.toDouble() ?? 0.0,
      salePrice: (map[ProductContract.colSalePrice] as num?)?.toDouble(),
      stock: map[ProductContract.colStock] as int? ?? 0,
      sku: map[ProductContract.colSku] as String?,
      status: ProductStatus.fromString(map[ProductContract.colStatus] as String? ?? 'AVAILABLE'),
      size: map[ProductContract.colSize] as String?,
      color: map[ProductContract.colColor] as String?,
      origin: map[ProductContract.colOrigin] as String?,
      careInstruction: CareInstruction.fromMap(map),
      isBestseller: map[ProductContract.colIsBestseller] == 1,
      isNew: map[ProductContract.colIsNew] == 1,
      rating: (map[ProductContract.colRating] as num?)?.toDouble() ?? 0.0,
      reviewCount: map[ProductContract.colReviewCount] as int? ?? 0,
      views: map[ProductContract.colViews] as int? ?? 0,
      createdAt: map[ProductContract.colCreatedAt] as int? ?? now,
      updatedAt: map[ProductContract.colUpdatedAt] as int? ?? now,
      primaryImage: map['primary_image'] as String?,
    );
  }
}