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
    return Voucher(
      id: map[VoucherContract.colId],
      code: map[VoucherContract.colCode],
      name: map[VoucherContract.colName],
      description: map[VoucherContract.colDescription],
      discountType: map[VoucherContract.colDiscountType],
      discountValue: (map[VoucherContract.colDiscountValue] ?? 0.0).toDouble(),
      minOrderValue: (map[VoucherContract.colMinOrderValue] ?? 0.0).toDouble(),
      maxDiscount: map[VoucherContract.colMaxDiscount] != null ? (map[VoucherContract.colMaxDiscount]).toDouble() : null,
      startDate: map[VoucherContract.colStartDate],
      endDate: map[VoucherContract.colEndDate],
      quantity: map[VoucherContract.colQuantity],
      usedCount: map[VoucherContract.colUsedCount] ?? 0,
      status: map[VoucherContract.colStatus] ?? 'ACTIVE',
      createdAt: map[VoucherContract.colCreatedAt],
      updatedAt: map[VoucherContract.colUpdatedAt],
    );
  }
}