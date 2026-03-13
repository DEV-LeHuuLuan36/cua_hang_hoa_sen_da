class VoucherContract {
  static const String tableName = 'vouchers';
  static const String colId = 'id';
  static const String colCode = 'code';
  static const String colName = 'name';
  static const String colDescription = 'description';
  static const String colDiscountType = 'discount_type';
  static const String colDiscountValue = 'discount_value';
  static const String colMinOrderValue = 'min_order_value';
  static const String colMaxDiscount = 'max_discount';
  static const String colStartDate = 'start_date';
  static const String colEndDate = 'end_date';
  static const String colQuantity = 'quantity';
  static const String colUsedCount = 'used_count';
  static const String colStatus = 'status';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';
}

class UserVoucherContract {
  static const String tableName = 'user_vouchers';
  static const String colId = 'id';
  static const String colUserId = 'user_id';
  static const String colVoucherId = 'voucher_id';
  static const String colUsedAt = 'used_at';
  static const String colOrderId = 'order_id';
}