import '../../database/contracts/voucher_contract.dart';

class UserVoucher {
  final String id;
  final String userId;
  final String voucherId;
  final int? usedAt;
  final String? orderId;

  UserVoucher({
    required this.id,
    required this.userId,
    required this.voucherId,
    this.usedAt,
    this.orderId,
  });

  Map<String, dynamic> toMap() {
    return {
      UserVoucherContract.colId: id,
      UserVoucherContract.colUserId: userId,
      UserVoucherContract.colVoucherId: voucherId,
      UserVoucherContract.colUsedAt: usedAt,
      UserVoucherContract.colOrderId: orderId,
    };
  }

  factory UserVoucher.fromMap(Map<String, dynamic> map) {
    return UserVoucher(
      id: map[UserVoucherContract.colId] as String? ?? '',
      userId: map[UserVoucherContract.colUserId] as String? ?? '',
      voucherId: map[UserVoucherContract.colVoucherId] as String? ?? '',
      usedAt: map[UserVoucherContract.colUsedAt] as int?,
      orderId: map[UserVoucherContract.colOrderId] as String?,
    );
  }
}