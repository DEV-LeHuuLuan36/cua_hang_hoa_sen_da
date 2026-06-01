import '../../database/contracts/voucher_contract.dart';

class Voucher {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String discountType; // 'PERCENT' hoặc 'FIXED'
  final double discountValue;
  final double minOrderValue;
  final double? maxDiscount;
  final int startDate;
  final int endDate;
  final int quantity;
  final int usedCount;
  final String status; // 'ACTIVE', 'EXPIRED', 'DISABLED'
  final int createdAt;
  final int updatedAt;

  Voucher({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderValue = 0.0,
    this.maxDiscount,
    required this.startDate,
    required this.endDate,
    required this.quantity,
    this.usedCount = 0,
    this.status = 'ACTIVE',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      VoucherContract.colId: id,
      VoucherContract.colCode: code,
      VoucherContract.colName: name,
      VoucherContract.colDescription: description,
      VoucherContract.colDiscountType: discountType,
      VoucherContract.colDiscountValue: discountValue,
      VoucherContract.colMinOrderValue: minOrderValue,
      VoucherContract.colMaxDiscount: maxDiscount,
      VoucherContract.colStartDate: startDate,
      VoucherContract.colEndDate: endDate,
      VoucherContract.colQuantity: quantity,
      VoucherContract.colUsedCount: usedCount,
      VoucherContract.colStatus: status,
      VoucherContract.colCreatedAt: createdAt,
      VoucherContract.colUpdatedAt: updatedAt,
    };
  }

  factory Voucher.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Voucher(
      id: map[VoucherContract.colId] as String? ?? '',
      code: map[VoucherContract.colCode] as String? ?? '',
      name: map[VoucherContract.colName] as String? ?? '',
      description: map[VoucherContract.colDescription] as String?,
      discountType: map[VoucherContract.colDiscountType] as String? ?? 'PERCENT',
      discountValue: (map[VoucherContract.colDiscountValue] as num?)?.toDouble() ?? 0.0,
      minOrderValue: (map[VoucherContract.colMinOrderValue] as num?)?.toDouble() ?? 0.0,
      maxDiscount: (map[VoucherContract.colMaxDiscount] as num?)?.toDouble(),
      startDate: map[VoucherContract.colStartDate] as int? ?? now,
      endDate: map[VoucherContract.colEndDate] as int? ?? now,
      quantity: map[VoucherContract.colQuantity] as int? ?? 0,
      usedCount: map[VoucherContract.colUsedCount] as int? ?? 0,
      status: map[VoucherContract.colStatus] as String? ?? 'ACTIVE',
      createdAt: map[VoucherContract.colCreatedAt] as int? ?? now,
      updatedAt: map[VoucherContract.colUpdatedAt] as int? ?? now,
    );
  }
}