class ReviewContract {
  static const String tableName = 'reviews';
  static const String colId = 'id';
  static const String colUserId = 'user_id';
  static const String colProductId = 'product_id';
  static const String colOrderId = 'order_id';
  static const String colRating = 'rating';
  static const String colComment = 'comment';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';
}

class ReviewImageContract {
  static const String tableName = 'review_images';
  static const String colId = 'id';
  static const String colReviewId = 'review_id';
  static const String colImageUrl = 'image_url';
  static const String colCreatedAt = 'created_at';
}