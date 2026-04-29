import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../database/daos/voucher_dao.dart';
import '../../../database/contracts/voucher_contract.dart';

class MyVouchersScreen extends StatefulWidget {
  const MyVouchersScreen({Key? key}) : super(key: key);

  @override
  State<MyVouchersScreen> createState() => _MyVouchersScreenState();
}

class _MyVouchersScreenState extends State<MyVouchersScreen> {
  final VoucherDao _voucherDao = VoucherDao();
  List<Map<String, dynamic>> _vouchers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    try {
      final vouchers = await _voucherDao.getAllActiveVouchers();
      setState(() {
        _vouchers = vouchers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text('Kho Voucher', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w700)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _vouchers.isEmpty
              ? _buildEmptyState(context)
              : _buildVoucherList(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 80, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'Chưa có voucher nào',
            style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vouchers.length,
      itemBuilder: (context, index) {
        final voucher = _vouchers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildVoucherCard(context, voucher),
        );
      },
    );
  }

  Widget _buildVoucherCard(BuildContext context, Map<String, dynamic> voucher) {
    final colorScheme = Theme.of(context).colorScheme;
    final voucherType = voucher[VoucherContract.colVoucherType] ?? 'discount';
    final discountType = voucher[VoucherContract.colDiscountType] ?? '';
    final discountValue = (voucher[VoucherContract.colDiscountValue] as num?)?.toDouble() ?? 0;
    final minOrder = (voucher[VoucherContract.colMinOrderValue] as num?)?.toDouble() ?? 0;
    final code = voucher[VoucherContract.colCode] ?? '';
    final name = voucher[VoucherContract.colName] ?? '';
    final description = voucher[VoucherContract.colDescription] ?? '';
    final quantity = voucher[VoucherContract.colQuantity] as int? ?? 0;
    final usedCount = voucher[VoucherContract.colUsedCount] as int? ?? 0;
    final endDate = voucher[VoucherContract.colEndDate] as int?;
    final isNoExpiry = endDate == null;
    final isUsageExhausted = usedCount >= quantity;
    final isExpired = !isNoExpiry && DateTime.now().millisecondsSinceEpoch > endDate;
    final isDisabled = isUsageExhausted || isExpired;

    final gradientColors = _getGradientColors(voucherType);

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: isDisabled ? Border.all(color: colorScheme.outlineVariant, width: 1.5) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 90,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (voucherType == 'shipping')
                    const Icon(Icons.local_shipping, color: Colors.white, size: 28)
                  else
                    Text(
                      discountType == 'percent'
                          ? '${discountValue.toInt()}%'
                          : '${(discountValue / 1000).toStringAsFixed(0)}K',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    voucherType == 'shipping' ? 'SHIP' : 'GIẢM',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: voucherType == 'shipping'
                                ? Colors.blue.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              code,
                              style: TextStyle(
                                color: voucherType == 'shipping' ? Colors.blue : Colors.orange[700],
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        if (isUsageExhausted) ...[
                          const SizedBox(width: 4),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'HẾT LƯỢT',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        if (isExpired) ...[
                          const SizedBox(width: 4),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'HẾT HẠN',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      style: TextStyle(color: colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 11, color: isExpired ? AppColors.error : colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          isNoExpiry
                              ? 'Không thời hạn'
                              : 'HSD: ${DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(endDate))}',
                          style: TextStyle(
                            color: isExpired ? AppColors.error : colorScheme.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (minOrder > 0) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.shopping_cart, size: 11, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            'Tối thiểu: ${_formatMoney(minOrder)}',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton(
                onPressed: isDisabled
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context, voucher);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: voucherType == 'shipping' ? Colors.blue : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                  disabledBackgroundColor: colorScheme.surfaceContainerHighest,
                  disabledForegroundColor: colorScheme.onSurfaceVariant,
                ),
                child: const Text('Dùng ngay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getGradientColors(String type) {
    switch (type) {
      case 'shipping':
        return [const Color(0xFF3498db), const Color(0xFF2980b9)];
      case 'discount':
        return [const Color(0xFFe67e22), const Color(0xFFd35400)];
      default:
        return [AppColors.primary, AppColors.primaryDark];
    }
  }

  String _formatMoney(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return '${value.toInt()}đ';
  }
}
