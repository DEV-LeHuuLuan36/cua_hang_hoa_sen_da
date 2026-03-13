class ProductContract {
  static const String tableName = 'products';

  static const String colId = 'id';
  static const String colCategoryId = 'category_id';
  static const String colName = 'name';
  static const String colScientificName = 'scientific_name';
  static const String colDescription = 'description';
  static const String colPrice = 'price';
  static const String colSalePrice = 'sale_price';
  static const String colStock = 'stock';
  static const String colSku = 'sku';
  static const String colStatus = 'status';
  static const String colSize = 'size';
  static const String colColor = 'color';
  static const String colOrigin = 'origin';

  // Care Instructions (được gộp trực tiếp vào bảng products)
  static const String colCareLevel = 'care_level';
  static const String colLightRequirement = 'light_requirement';
  static const String colWaterRequirement = 'water_requirement';

  static const String colIsBestseller = 'is_bestseller';
  static const String colIsNew = 'is_new';
  static const String colRating = 'rating';
  static const String colReviewCount = 'review_count';
  static const String colViews = 'views';

  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';
}

class ProductImageContract {
  static const String tableName = 'product_images';

  static const String colId = 'id';
  static const String colProductId = 'product_id';
  static const String colImageUrl = 'image_url';
  static const String colIsPrimary = 'is_primary';
  static const String colSortOrder = 'sort_order';
  static const String colCreatedAt = 'created_at';
}