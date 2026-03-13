class OrderContract {
  static const String tableName = 'orders';

  static const String colId = 'id';
  static const String colOrderNumber = 'order_number';
  static const String colUserId = 'user_id';
  static const String colAddressId = 'address_id';
  static const String colVoucherId = 'voucher_id';
  static const String colSubtotal = 'subtotal';
  static const String colShippingFee = 'shipping_fee';
  static const String colDiscount = 'discount';
  static const String colTotal = 'total';

  // Tích hợp từ bảng payments
  static const String colPaymentMethod = 'payment_method';
  static const String colPaymentStatus = 'payment_status';
  static const String colPaymentDate = 'payment_date';

  static const String colOrderStatus = 'order_status';
  static const String colNote = 'note';

  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';
}

class OrderItemContract {
  static const String tableName = 'order_items';
  static const String colId = 'id';
  static const String colOrderId = 'order_id';
  static const String colProductId = 'product_id';
  static const String colProductName = 'product_name';
  static const String colVariant = 'variant';
  static const String colQuantity = 'quantity';
  static const String colPrice = 'price';
  static const String colTotal = 'total';
}

class OrderTrackingContract {
  static const String tableName = 'order_tracking';
  static const String colId = 'id';
  static const String colOrderId = 'order_id';
  static const String colStatus = 'status';
  static const String colNote = 'note';
  static const String colCreatedAt = 'created_at';
}