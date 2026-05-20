import '../daos/voucher_dao.dart';

class VoucherRepository {
  final VoucherDao _voucherDao;

  VoucherRepository({VoucherDao? voucherDao}) : _voucherDao = voucherDao ?? VoucherDao();

  Future<List<Map<String, dynamic>>> getActiveDiscountVouchers() {
    return _voucherDao.getActiveDiscountVouchers();
  }

  Future<List<Map<String, dynamic>>> getActiveShippingVouchers() {
    return _voucherDao.getActiveShippingVouchers();
  }

  Future<VoucherValidationResult> validateVoucher({
    required String code,
    required double totalAmount,
  }) {
    return _voucherDao.validateVoucher(code: code, totalAmount: totalAmount);
  }

  Future<bool> decrementUsageLimit(String voucherId) {
    return _voucherDao.decrementUsageLimit(voucherId);
  }
}
