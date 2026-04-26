import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/constants/route_names.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../models/common/address.dart';
import '../../../models/cart/cart_item.dart';
import '../../../models/product/succulent.dart';
import '../../../widgets/common/pressable_scale.dart';
import '../../../database/daos/voucher_dao.dart';
import '../../../services/notification_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> with SingleTickerProviderStateMixin {
  static const double _cardRadius = 16;
  static const double _sectionSpacing = 20;

  final VoucherDao _voucherDao = VoucherDao();
  final NotificationService _notificationService = NotificationService();
  String _selectedPaymentMethod = 'COD';
  Map<String, dynamic>? _selectedVoucher;
  bool _isAutoFreeshipApplied = false;
  bool _isSubmitting = false;
  bool _isInitialLoading = true;
  double _shippingFee = 30000;
  double _discountAmount = 0;
  double _subTotal = 0;
  Address? _selectedAddress;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationService.initialize();
      _calculateInitialTotals();
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _calculateInitialTotals() async {
    final cartProvider = context.read<CartProvider>();
    final productProvider = context.read<ProductProvider>();
    final userProvider = context.read<UserProvider>();
    final authProvider = context.read<AuthProvider>();

    final userId = authProvider.currentUser?.id;

    // Load sổ địa chỉ của user nếu có
    if (userId != null) {
      await userProvider.loadUserAddresses(userId);
      if (userProvider.addresses.isNotEmpty) {
        _selectedAddress = userProvider.addresses.firstWhere(
              (addr) => addr.isDefault,
          orElse: () => userProvider.addresses.first,
        );
      }
    }

    if (productProvider.products.isEmpty) {
      await productProvider.loadAllProducts();
    }

    double calculatedSubTotal = 0;
    for (var item in cartProvider.cartItems) {
      try {
        final product = productProvider.products.firstWhere((p) => p.id == item.productId);
        calculatedSubTotal += product.price * item.quantity;
      } catch (e) {
        // Bỏ qua nếu không tìm thấy sản phẩm
      }
    }

    if (!mounted) return;
    setState(() {
      _subTotal = calculatedSubTotal;
      _isInitialLoading = false;
    });
    _checkAutoVoucher();
  }

  void _checkAutoVoucher() {
    final today = DateTime.now();
    if (!mounted) return;
    setState(() {
      if (today.day == today.month) {
        _isAutoFreeshipApplied = true;
        _shippingFee = 0;
      } else {
        _isAutoFreeshipApplied = false;
        _shippingFee = 30000;
      }
    });
  }

  void _applyVoucher(Map<String, dynamic>? voucher) {
    final today = DateTime.now();
    setState(() {
      _selectedVoucher = voucher;
      _discountAmount = 0;
      _shippingFee = 30000;

      if (voucher == null) {
        if (today.day == today.month) {
          _isAutoFreeshipApplied = true;
          _shippingFee = 0;
        } else {
          _isAutoFreeshipApplied = false;
        }
        return;
      }

      _isAutoFreeshipApplied = false;

      final String type = voucher['type'] ?? '';
      final double value = (voucher['value'] as num?)?.toDouble() ?? 0;
      final double? maxDiscount = (voucher['maxDiscount'] as num?)?.toDouble();

      switch (type) {
        case 'freeship':
          _shippingFee = 0;
          _discountAmount = 0;
          break;
        case 'percent':
          final calculated = (_subTotal * value / 100);
          _discountAmount = (maxDiscount != null && calculated > maxDiscount) ? maxDiscount : calculated;
          break;
        case 'fixed':
          _discountAmount = value;
          break;
        default:
          _discountAmount = 0;
      }
    });
  }

  Future<bool> _validateStockBeforeCheckout() async {
    final cartProvider = context.read<CartProvider>();
    final productProvider = context.read<ProductProvider>();

    if (productProvider.products.isEmpty) {
      await productProvider.loadAllProducts();
    }

    for (final item in cartProvider.cartItems) {
      try {
        final product = productProvider.products.firstWhere((p) => p.id == item.productId);
        if (item.quantity > product.stock) {
          if (!mounted) return false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sản phẩm "${product.name}" chỉ còn ${product.stock} trong kho.'),
              backgroundColor: AppColors.error,
            ),
          );
          return false;
        }
      } catch (_) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Một số sản phẩm không còn khả dụng, vui lòng kiểm tra lại giỏ hàng.'),
            backgroundColor: AppColors.error,
          ),
        );
        return false;
      }
    }
    return true;
  }

  String _formatMoney(double value) => '${value.toInt()}đ';

  Succulent? _findProductById(ProductProvider productProvider, String productId) {
    for (final product in productProvider.products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(_cardRadius),
      boxShadow: [
        BoxShadow(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
    );
  }

  Widget _buildAddressSection(BuildContext context) {
    return InkWell(
      onTap: () async {
        final selected = await Navigator.pushNamed(context, RouteNames.addressBook);
        if (selected is Address) {
          setState(() => _selectedAddress = selected);
        }
      },
      borderRadius: BorderRadius.circular(_cardRadius),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.location_on_rounded, color: AppColors.surface),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _selectedAddress == null
                  ? Text(
                      'Vui lòng thêm địa chỉ nhận hàng',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.error,
                            fontStyle: FontStyle.italic,
                          ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedAddress!.fullName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedAddress!.phone,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_selectedAddress!.addressLine}, ${_selectedAddress!.ward}, ${_selectedAddress!.district}, ${_selectedAddress!.city}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_offer_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Mã giảm giá',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () async {
                  final result = await Navigator.pushNamed(context, RouteNames.myVouchers);
                  if (result is Map<String, dynamic>) {
                    HapticFeedback.lightImpact();
                    _applyVoucher(result);
                  }
                },
                child: Text(_selectedVoucher != null ? 'Thay đổi' : 'Chọn mã'),
              ),
            ],
          ),
          if (_selectedVoucher != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đã áp dụng mã: ${_selectedVoucher!['code']}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _applyVoucher(null),
                    child: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          if (_isAutoFreeshipApplied)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tự động áp dụng: Freeship Ngày Đôi',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedProductsSection(BuildContext context) {
    if (_isInitialLoading) {
      return _buildProductsSkeletonSection();
    }

    final cartProvider = context.watch<CartProvider>();
    final productProvider = context.watch<ProductProvider>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Sản phẩm đã chọn'),
          const SizedBox(height: 12),
          ...cartProvider.cartItems.map((item) {
            final product = _findProductById(productProvider, item.productId);
            final name = product?.name ?? 'Sản phẩm không xác định';
            final price = product?.price ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_florist_rounded, color: AppColors.primaryDark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Số lượng: ${item.quantity}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatMoney(price * item.quantity),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption({
    required BuildContext context,
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentMethod == value;
    return PressableScale(
      pressedScale: 0.95,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _selectedPaymentMethod = value);
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.fastOutSlowIn,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.22) : AppColors.background,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.secondary.withValues(alpha: 0.6),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? AppColors.primaryDark : AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Phương thức thanh toán'),
          const SizedBox(height: 12),
          _buildPaymentMethodOption(
            context: context,
            value: 'COD',
            title: 'Thanh toán khi nhận hàng',
            subtitle: 'Thanh toán trực tiếp cho shipper khi nhận đơn',
            icon: Icons.payments_rounded,
          ),
          _buildPaymentMethodOption(
            context: context,
            value: 'BANKING',
            title: 'Chuyển khoản ngân hàng',
            subtitle: 'Thanh toán trước để xử lý đơn nhanh hơn',
            icon: Icons.account_balance_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummarySection(BuildContext context, double totalAmount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildSummaryRow(context, 'Tạm tính', _formatMoney(_subTotal)),
          _buildSummaryRow(
            context,
            'Phí giao hàng',
            _shippingFee == 0 ? 'Miễn phí' : _formatMoney(_shippingFee),
            valueColor: _shippingFee == 0 ? AppColors.success : AppColors.textPrimary,
          ),
          if (_discountAmount > 0)
            _buildSummaryRow(
              context,
              'Giảm giá voucher',
              '-${_formatMoney(_discountAmount)}',
              valueColor: AppColors.error,
            ),
          const Divider(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng cộng',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
              Text(
                _formatMoney(totalAmount),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onPlaceOrderPressed(
    BuildContext context,
    List<CartItem> items,
    double totalAmount,
  ) async {
    if (_isSubmitting) return;

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn hoặc thêm địa chỉ nhận hàng trước khi thanh toán!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Kiểm tra voucher usage limit trước khi đặt hàng
    if (_selectedVoucher != null) {
      final voucherId = _selectedVoucher!['id'] as String?;
      if (voucherId != null) {
        final remaining = await _voucherDao.getRemainingUsage(voucherId);
        if (remaining <= 0) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Voucher đã hết lượt sử dụng!'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
      }
    }

    final stockValid = await _validateStockBeforeCheckout();
    if (!stockValid) return;

    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();

    final userId = authProvider.currentUser?.id;
    final cart = cartProvider.cart;
    if (userId == null || cart == null || items.isEmpty) return;

    setState(() => _isSubmitting = true);

    final success = await orderProvider.placeOrder(
      userId: userId,
      cartId: cart.id,
      cartItems: items.map((e) => {'product_id': e.productId, 'quantity': e.quantity}).toList(),
      totalAmount: totalAmount,
      voucherId: _selectedVoucher?['id'],
      discountAmount: _discountAmount,
      shippingFee: _shippingFee,
      paymentMethod: _selectedPaymentMethod,
      addressId: _selectedAddress!.id,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      // Trừ usage limit của voucher sau khi đặt hàng thành công
      if (_selectedVoucher != null) {
        final voucherId = _selectedVoucher!['id'] as String?;
        if (voucherId != null) {
          await _voucherDao.decrementUsageLimit(voucherId);
        }
      }

      // Đẩy thông báo thành công
      await _notificationService.showOrderSuccess(
        title: 'Đặt hàng thành công! 🎉',
        body: 'Cảm ơn bạn đã mua sắm. Đơn hàng sen đá của bạn đang chờ xử lý.',
      );

      await cartProvider.loadCart(userId);
      await orderProvider.loadMyOrders(userId);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => _SuccessOrderDialog(
          onViewOrders: () {
            Navigator.pop(ctx);
            Navigator.pushReplacementNamed(context, RouteNames.orderList);
          },
        ),
      );
    }
  }

  Widget _buildProductsSkeletonSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Sản phẩm đã chọn'),
          const SizedBox(height: 12),
          ...List.generate(3, (_) => _buildSkeletonItem()),
        ],
      ),
    );
  }

  Widget _buildSkeletonItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _ShimmerBox(
            controller: _shimmerController,
            width: 52,
            height: 52,
            borderRadius: 12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(controller: _shimmerController, width: double.infinity, height: 12, borderRadius: 8),
                const SizedBox(height: 8),
                _ShimmerBox(controller: _shimmerController, width: 120, height: 10, borderRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ShimmerBox(controller: _shimmerController, width: 60, height: 12, borderRadius: 8),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: _isSubmitting ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        child: Container(
          color: AppColors.textPrimary.withValues(alpha: 0.2),
          alignment: Alignment.center,
          child: Container(
            width: 180,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ShimmerBox(controller: _shimmerController, width: 120, height: 12, borderRadius: 8),
                const SizedBox(height: 10),
                _ShimmerBox(controller: _shimmerController, width: 90, height: 10, borderRadius: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final items = cartProvider.cartItems;

    double totalAmount = (_subTotal + _shippingFee - _discountAmount);
    if (totalAmount < 0) totalAmount = 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Xác nhận Đơn hàng', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, 'Địa chỉ nhận hàng'),
                const SizedBox(height: 8),
                _buildAddressSection(context),
                const SizedBox(height: _sectionSpacing),
                _buildSectionTitle(context, 'Khuyến mãi'),
                const SizedBox(height: 8),
                _buildVoucherSection(context),
                const SizedBox(height: _sectionSpacing),
                _buildPaymentMethodSection(context),
                const SizedBox(height: _sectionSpacing),
                _buildSelectedProductsSection(context),
                const SizedBox(height: _sectionSpacing),
                _buildOrderSummarySection(context, totalAmount),
                const SizedBox(height: 8),
              ],
            ),
          ),
          if (_isSubmitting) _buildLoadingOverlay(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isSubmitting ? null : () => _onPlaceOrderPressed(context, items, totalAmount),
            child: const Text('ĐẶT HÀNG NGAY', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final AnimationController controller;
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerBox({
    required this.controller,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1 + (controller.value * 2), 0),
              end: Alignment(1 + (controller.value * 2), 0),
              colors: const [
                Color(0xFFE6E6E6),
                Color(0xFFF5F5F5),
                Color(0xFFE6E6E6),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SuccessOrderDialog extends StatelessWidget {
  final VoidCallback onViewOrders;

  const _SuccessOrderDialog({required this.onViewOrders});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.2, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            builder: (context, value, child) => Transform.scale(scale: value, child: child),
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 54),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Đặt hàng thành công!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onViewOrders,
          child: const Text('XEM ĐƠN HÀNG', style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }
}