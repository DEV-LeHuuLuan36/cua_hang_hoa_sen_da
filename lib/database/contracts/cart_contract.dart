class CartContract {
  static const String tableName = 'cart';
  static const String colId = 'id';
  static const String colUserId = 'user_id';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';
}

class CartItemContract {
  static const String tableName = 'cart_items';
  static const String colId = 'id';
  static const String colCartId = 'cart_id';
  static const String colProductId = 'product_id';
  static const String colQuantity = 'quantity';
  static const String colVariant = 'variant';
  static const String colAddedAt = 'added_at';
}