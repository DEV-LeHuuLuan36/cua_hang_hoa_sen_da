import 'package:flutter/foundation.dart';
import '../database/repositories/voucher_repository.dart';
import '../database/daos/voucher_dao.dart';

class VoucherProvider with ChangeNotifier {
  final VoucherRepository _voucherRepository;

  VoucherProvider({VoucherRepository? voucherRepository})
      : _voucherRepository = voucherRepository ?? VoucherRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _discountVouchers = [];
  List<Map<String, dynamic>> get discountVouchers => _discountVouchers;

  List<Map<String, dynamic>> _shippingVouchers = [];
  List<Map<String, dynamic>> get shippingVouchers => _shippingVouchers;

  Future<void> loadActiveVouchers() async {
    _isLoading = true;
    notifyListeners();

    final results = await Future.wait([
      _voucherRepository.getActiveDiscountVouchers(),
      _voucherRepository.getActiveShippingVouchers(),
    ]);

    _discountVouchers = results[0];
    _shippingVouchers = results[1];

    _isLoading = false;
    notifyListeners();
  }

  Future<VoucherValidationResult> validateVoucher({
    required String code,
    required double totalAmount,
  }) {
    return _voucherRepository.validateVoucher(code: code, totalAmount: totalAmount);
  }

  Future<void> decrementUsageLimit(String voucherId) async {
    await _voucherRepository.decrementUsageLimit(voucherId);
  }
}
