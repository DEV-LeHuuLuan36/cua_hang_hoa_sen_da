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
import '../../../providers/voucher_provider.dart';
import '../../../services/notification_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> with SingleTickerProviderStateMixin {
  static const double _cardRadius = 16;
  static const double _sectionSpacing = 20;
  static const double _shippingFeeDefault = 30000;

  final NotificationService _notificationService = NotificationService();
  final TextEditingController _voucherController = TextEditingController();

  String _selectedPaymentMethod = 'COD';
  Map<String, dynamic>? _appliedDiscountVoucher;
  Map<String, dynamic>? _appliedShippingVoucher;
  bool _isAutoFreeshipApplied = false;
  bool _isSubmitting = false;
  bool _isInitialLoading = true;
  bool _isApplyingVoucher = false;
  String? _voucherError;
  double _shippingFee = _shippingFeeDefault;
  double _discountAmount = 0;
  double _shippingDiscountAmount = 0;
  double _subTotal = 0;
  Address? _selectedAddress;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _notificationService.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateInitialTotals();
      _loadUserAddresses();
    });
  }

  Future<void> _loadUserAddresses() async {
    final userProvider = context.read<UserProvider>();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    if (userId != null && userProvider.addresses.isEmpty) {
      userProvider.loadUserAddresses(userId);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserAddresses();
  }

  Future<void> _reloadAddresses() async {
    final userProvider = context.read<UserProvider>();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    if (userId != null) {
      await userProvider.loadUserAddresses(userId);
      if (userProvider.addresses.isNotEmpty && _selectedAddress == null) {
        setState(() {
          _selectedAddress = userProvider.addresses.firstWhere(
            (addr) => addr.isDefault,
            orElse: () => userProvider.addresses.first,
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _voucherController.dispose();
    super.dispose();
  }

  Future<void> _applyVoucherByCode(String code) async {
    if (code.trim().isEmpty) {
      setState(() => _voucherError = 'Vui lòng nhập mã giảm giá');
      return;
    }
    setState(() {
      _isApplyingVoucher = true;
      _voucherError = null;
    });
    try {
      final result = await context.read<VoucherProvider>().validateVoucher(code: code.trim(), totalAmount: _subTotal);
      if (!result.isValid) {
        setState(() {
          _voucherError = result.errorMessage ?? 'Mã giảm giá không hợp lệ';
          _isApplyingVoucher = false;
        });
        return;
      }
      final voucher = result.voucher!;
      final voucherType = voucher['voucher_type'] ?? 'discount';
      HapticFeedback.lightImpact();
      if (voucherType == 'shipping') {
        setState(() {
          _appliedShippingVoucher = voucher;
          _shippingDiscountAmount = _shippingFee;
          _shippingFee = 0;
          _isAutoFreeshipApplied = false;
          _isApplyingVoucher = false;
        });
        _voucherController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Áp dụng mã ${voucher['code']} - Freeship!'), backgroundColor: Colors.blue),
          );
        }
      } else {
        _applyDiscountVoucher(voucher);
        _voucherController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Áp dụng mã ${voucher['code']} - Giảm giá!'), backgroundColor: AppColors.success),
          );
        }
      }
    } catch (e) {
      setState(() {
        _voucherError = 'Đã xảy ra lỗi. Vui lòng thử lại.';
        _isApplyingVoucher = false;
      });
    }
  }

  void _applyDiscountVoucher(Map<String, dynamic>? voucher) {
    setState(() {
      _appliedDiscountVoucher = voucher;
      _discountAmount = 0;
      if (voucher == null) return;
      final String type = voucher['discount_type'] ?? '';
      final double value = (voucher['discount_value'] as num?)?.toDouble() ?? 0;
      final double? maxDiscount = (voucher['max_discount'] as num?)?.toDouble();
      switch (type) {
        case 'percent':
          final calculated = (_subTotal * value / 100);
          _discountAmount = (maxDiscount != null && calculated > maxDiscount) ? maxDiscount : calculated;
          break;
        case 'fixed':
          _discountAmount = value > _subTotal ? _subTotal : value;
          break;
        default:
          _discountAmount = 0;
      }
    });
  }

  void _applyShippingVoucher(Map<String, dynamic>? voucher) {
    setState(() {
      _appliedShippingVoucher = voucher;
      if (voucher != null) {
        _shippingDiscountAmount = _shippingFee;
        _shippingFee = 0;
        _isAutoFreeshipApplied = false;
      } else {
        _shippingFee = _shippingFeeDefault;
        _shippingDiscountAmount = 0;
      }
    });
  }

  void _removeDiscountVoucher() => _applyDiscountVoucher(null);
  void _removeShippingVoucher() => _applyShippingVoucher(null);

  Future<void> _calculateInitialTotals() async {
    final cartProvider = context.read<CartProvider>();
    
    // Guard: Chỉ tính khi đã có items được chọn và chưa từng tính
    if (cartProvider.selectedItems.isEmpty) {
      // Không có sản phẩm được chọn - vẫn set loading = false để hiển thị UI
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
      return;
    }
    
    if (!_isInitialLoading && _subTotal > 0) return;
    
    final productProvider = context.read<ProductProvider>();
    final userProvider = context.read<UserProvider>();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    if (userId != null) {
      await userProvider.loadUserAddresses(userId);
      if (userProvider.addresses.isNotEmpty) {
        _selectedAddress = userProvider.addresses.firstWhere(
          (addr) => addr.isDefault,
          orElse: () => userProvider.addresses.first,
        );
      }
    }
    if (productProvider.products.isEmpty) await productProvider.loadAllProducts();
    
    double calculatedSubTotal = 0;
    // Chỉ tính tổng cho các sản phẩm được chọn từ CartProvider
    for (var item in cartProvider.selectedItems) {
      try {
        final product = productProvider.products.firstWhere((p) => p.id == item.productId);
        calculatedSubTotal += product.price * item.quantity;
      } catch (_) {
        // Sản phẩm không tìm thấy - bỏ qua
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
        _shippingDiscountAmount = _shippingFeeDefault;
        _shippingFee = 0;
      } else {
        _isAutoFreeshipApplied = false;
      }
    });
  }

  void _showVoucherBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _VoucherBottomSheet(
        subTotal: _subTotal,
        appliedDiscountVoucher: _appliedDiscountVoucher,
        appliedShippingVoucher: _appliedShippingVoucher,
        onDiscountVoucherSelected: (v) {
          HapticFeedback.lightImpact();
          _applyDiscountVoucher(v);
          setState(() {});
        },
        onShippingVoucherSelected: (v) {
          HapticFeedback.lightImpact();
          _applyShippingVoucher(v);
          setState(() {});
        },
        onDiscountVoucherRemoved: () {
          _removeDiscountVoucher();
          setState(() {});
        },
        onShippingVoucherRemoved: () {
          _removeShippingVoucher();
          setState(() {});
        },
      ),
    );
  }

  Future<bool> _validateStockBeforeCheckout() async {
    final cartProvider = context.read<CartProvider>();
    final productProvider = context.read<ProductProvider>();
    if (productProvider.products.isEmpty) await productProvider.loadAllProducts();
    // Chỉ kiểm tra tồn kho cho các sản phẩm được chọn
    for (final item in cartProvider.selectedItems) {
      try {
        final product = productProvider.products.firstWhere((p) => p.id == item.productId);
        if (item.quantity > product.stock) {
          if (!mounted) return false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sản phẩm "${product.name}" chỉ còn ${product.stock} trong kho.'), backgroundColor: AppColors.error),
          );
          return false;
        }
      } catch (_) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Một số sản phẩm không còn khả dụng.'), backgroundColor: AppColors.error),
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

  BoxDecoration _cardDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(_cardRadius),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cartProvider = context.watch<CartProvider>();
    // Lấy danh sách từ CartProvider
    final checkoutItems = cartProvider.selectedItems;
    double totalAmount = _subTotal + _shippingFeeDefault - _discountAmount - _shippingDiscountAmount;
    if (totalAmount < 0) totalAmount = 0;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text('Xác nhận Đơn hàng', style: TextStyle(color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
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
                _buildSelectedProductsSection(context, checkoutItems),
                const SizedBox(height: _sectionSpacing),
                _buildOrderSummarySection(context, totalAmount),
                const SizedBox(height: 8),
              ],
            ),
          ),
          if (_isSubmitting) _buildLoadingOverlay(context),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isSubmitting ? null : () => _onPlaceOrderPressed(context, checkoutItems, totalAmount),
            child: const Text('ĐẶT HÀNG NGAY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface));
  }

  Widget _buildAddressSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () async {
        final userProvider = context.read<UserProvider>();
        await _reloadAddresses();
        final selected = await Navigator.pushNamed(context, RouteNames.addressBook);
        if (selected is Address) {
          setState(() => _selectedAddress = selected);
        } else {
          await _reloadAddresses();
          if (userProvider.addresses.isNotEmpty && _selectedAddress == null) {
            setState(() {
              _selectedAddress = userProvider.addresses.firstWhere(
                (addr) => addr.isDefault,
                orElse: () => userProvider.addresses.first,
              );
            });
          }
        }
      },
      borderRadius: BorderRadius.circular(_cardRadius),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.location_on_rounded, color: colorScheme.surface),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _selectedAddress == null
                  ? Text('Vui lòng thêm địa chỉ nhận hàng', style: TextStyle(color: AppColors.error, fontStyle: FontStyle.italic))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedAddress!.fullName, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                        const SizedBox(height: 2),
                        Text(_selectedAddress!.phone, style: textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(
                          '${_selectedAddress!.addressLine}, ${_selectedAddress!.ward}, ${_selectedAddress!.district}, ${_selectedAddress!.city}',
                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _voucherController,
                  style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Nhập mã giảm giá',
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    errorText: _voucherError,
                    errorStyle: TextStyle(fontSize: 12, color: AppColors.error),
                    isDense: true,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (value) => _applyVoucherByCode(value),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isApplyingVoucher ? null : () => _applyVoucherByCode(_voucherController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isApplyingVoucher
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : const Text('ÁP DỤNG', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () => _showVoucherBottomSheet(context),
            icon: Icon(Icons.local_offer_rounded, size: 18, color: AppColors.primary),
            label: Text('Chọn mã giảm giá', style: TextStyle(color: AppColors.primary)),
          ),
          if (_appliedDiscountVoucher != null)
            _buildAppliedVoucherChip(context: context, voucher: _appliedDiscountVoucher!, type: 'discount', onRemove: _removeDiscountVoucher),
          if (_appliedShippingVoucher != null)
            _buildAppliedVoucherChip(context: context, voucher: _appliedShippingVoucher!, type: 'shipping', onRemove: _removeShippingVoucher),
          if (_isAutoFreeshipApplied && _appliedShippingVoucher == null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.blue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tự động: Freeship Ngày Đôi',
                      style: textTheme.bodySmall?.copyWith(color: Colors.blue, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppliedVoucherChip({
    required BuildContext context,
    required Map<String, dynamic> voucher,
    required String type,
    required VoidCallback onRemove,
  }) {
    final code = voucher['code'] ?? '';
    final isShipping = type == 'shipping';
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isShipping ? Colors.blue.withValues(alpha: 0.15) : AppColors.primaryLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isShipping ? Colors.blue : AppColors.primary),
      ),
      child: Row(
        children: [
          Icon(isShipping ? Icons.local_shipping : Icons.percent, color: isShipping ? Colors.blue : AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isShipping ? 'Freeship: $code' : 'Giảm giá: $code',
              style: TextStyle(color: isShipping ? Colors.blue : AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(12),
            child: Icon(
              Icons.close_rounded,
              color: isShipping ? Colors.blue : colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedProductsSection(BuildContext context, List<CartItem> checkoutItems) {
    if (_isInitialLoading) return _buildProductsSkeletonSection(context);
    final productProvider = context.watch<ProductProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Sản phẩm đã chọn (${checkoutItems.length})'),
          const SizedBox(height: 12),
          ...checkoutItems.map((item) {
            final product = _findProductById(productProvider, item.productId);
            final name = product?.name ?? 'Sản phẩm không xác định';
            final price = product?.price ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: product != null && product.primaryImage != null && product.primaryImage!.isNotEmpty
                        ? Image.asset(
                            product.primaryImage!,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.local_florist_rounded, color: AppColors.primaryDark),
                            ),
                          )
                        : Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.local_florist_rounded, color: AppColors.primaryDark),
                          ),
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
                          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Số lượng: ${item.quantity}',
                          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatMoney(price * item.quantity),
                    style: textTheme.titleSmall?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Phương thức thanh toán'),
          const SizedBox(height: 12),
          _buildPaymentMethodOption(
            context: context,
            value: 'COD',
            title: 'Thanh toán khi nhận hàng',
            subtitle: 'Thanh toán trực tiếp cho shipper',
            icon: Icons.payments_rounded,
          ),
          _buildPaymentMethodOption(
            context: context,
            value: 'BANKING',
            title: 'Chuyển khoản ngân hàng',
            subtitle: 'Thanh toán trước để xử lý nhanh hơn',
            icon: Icons.account_balance_rounded,
          ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.22) : colorScheme.surfaceContainerLowest,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.secondary.withValues(alpha: 0.6),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? AppColors.primaryDark : colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isSelected ? AppColors.primary : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummarySection(BuildContext context, double totalAmount) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          _buildSummaryRow(context, 'Tạm tính', _formatMoney(_subTotal)),
          _buildSummaryRow(
            context,
            'Phí vận chuyển',
            _formatMoney(_shippingFeeDefault),
            valueColor: _shippingFee == 0 ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
          ),
          if (_discountAmount > 0)
            _buildSummaryRow(context, 'Giảm giá hàng hóa', '-${_formatMoney(_discountAmount)}', valueColor: AppColors.error, isDiscount: true),
          if (_shippingDiscountAmount > 0)
            _buildSummaryRow(context, 'Giảm phí vận chuyển', '-${_formatMoney(_shippingDiscountAmount)}', valueColor: Colors.blue, isDiscount: true),
          Divider(height: 28, color: colorScheme.outlineVariant),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng cộng', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
              Text(_formatMoney(totalAmount), style: textTheme.titleLarge?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value, {Color? valueColor, bool isDiscount = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: isDiscount ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              color: valueColor ?? (isDiscount ? AppColors.error : colorScheme.onSurface),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onPlaceOrderPressed(BuildContext context, List<CartItem> items, double totalAmount) async {
    if (_isSubmitting) return;
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn địa chỉ nhận hàng!'), backgroundColor: AppColors.error),
      );
      return;
    }
    final stockValid = await _validateStockBeforeCheckout();
    if (!stockValid) return;
    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();
    final userId = authProvider.currentUser?.id;
    final cart = cartProvider.cart;
    if (userId == null || cart == null || items.isEmpty) return;

    // Step 1: Show payment gateway loading overlay
    setState(() => _isSubmitting = true);

    // Step 2: Simulate payment gateway API call (2 seconds)
    final paymentText = _selectedPaymentMethod == 'BANKING'
        ? 'Đang kết nối cổng thanh toán...'
        : 'Đang xử lý đơn hàng...';
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Step 3: Place the actual order
    final orderProvider = context.read<OrderProvider>();
    final success = await orderProvider.placeOrder(
      userId: userId,
      cartId: cart.id,
      cartItems: items.map((e) => {'product_id': e.productId, 'quantity': e.quantity}).toList(),
      totalAmount: totalAmount,
      voucherId: _appliedDiscountVoucher?['id'],
      discountAmount: _discountAmount,
      shippingFee: _shippingFee,
      paymentMethod: _selectedPaymentMethod,
      addressId: _selectedAddress!.id,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      // Step 4: Deduct voucher usage
      if (_appliedDiscountVoucher != null) {
        final voucherId = _appliedDiscountVoucher!['id'] as String?;
        if (voucherId != null) await context.read<VoucherProvider>().decrementUsageLimit(voucherId);
      }
      if (_appliedShippingVoucher != null) {
        final voucherId = _appliedShippingVoucher!['id'] as String?;
        if (voucherId != null) await context.read<VoucherProvider>().decrementUsageLimit(voucherId);
      }

      // Step 5: Show beautiful success dialog
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (ctx) => _SuccessDialog(
          onHomePressed: () async {
            // Clear cart items
            for (var item in items) {
              await cartProvider.removeItem(item.id);
            }
            cartProvider.clearSelectedItems();
            await orderProvider.loadMyOrders(userId);
            await _notificationService.showOrderSuccess(
              title: 'Đặt hàng thành công!',
              body: 'Cảm ơn bạn đã mua sắm.',
              payload: 'order_list',
            );
            if (!mounted) return;
            Navigator.pop(ctx);
            Navigator.pushNamedAndRemoveUntil(context, RouteNames.home, (route) => false);
          },
          onViewOrderPressed: () async {
            for (var item in items) {
              await cartProvider.removeItem(item.id);
            }
            cartProvider.clearSelectedItems();
            await orderProvider.loadMyOrders(userId);
            await _notificationService.showOrderSuccess(
              title: 'Đặt hàng thành công!',
              body: 'Cảm ơn bạn đã mua sắm.',
              payload: 'order_list',
            );
            if (!mounted) return;
            Navigator.pop(ctx);
            Navigator.pushReplacementNamed(context, RouteNames.orderList);
          },
        ),
      );
    }
  }

  Widget _buildProductsSkeletonSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Sản phẩm đã chọn'),
          const SizedBox(height: 12),
          ...List.generate(3, (_) => _buildSkeletonItem(context)),
        ],
      ),
    );
  }

  Widget _buildSkeletonItem(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _ShimmerBox(controller: _shimmerController, width: 52, height: 52, borderRadius: 12),
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

  Widget _buildLoadingOverlay(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: Container(
            width: 220,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _selectedPaymentMethod == 'BANKING'
                      ? 'Đang kết nối cổng thanh toán...'
                      : 'Đang xử lý đơn hàng...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vui lòng chờ trong giây lát',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== SUCCESS DIALOG ====================
class _SuccessDialog extends StatefulWidget {
  final VoidCallback onHomePressed;
  final VoidCallback onViewOrderPressed;

  const _SuccessDialog({
    required this.onHomePressed,
    required this.onViewOrderPressed,
  });

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 60),
                ),
                const SizedBox(height: 20),
                Text(
                  'Đặt hàng thành công!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cảm ơn bạn đã mua sắm tại Hoa Sen Đá.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: widget.onHomePressed,
                    child: const Text('VỀ TRANG CHỦ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: widget.onViewOrderPressed,
                  child: Text('XEM ĐƠN HÀNG', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== VOUCHER BOTTOM SHEET ====================
class _VoucherBottomSheet extends StatefulWidget {
  final double subTotal;
  final Map<String, dynamic>? appliedDiscountVoucher;
  final Map<String, dynamic>? appliedShippingVoucher;
  final Function(Map<String, dynamic>) onDiscountVoucherSelected;
  final Function(Map<String, dynamic>) onShippingVoucherSelected;
  final VoidCallback onDiscountVoucherRemoved;
  final VoidCallback onShippingVoucherRemoved;

  const _VoucherBottomSheet({
    required this.subTotal,
    this.appliedDiscountVoucher,
    this.appliedShippingVoucher,
    required this.onDiscountVoucherSelected,
    required this.onShippingVoucherSelected,
    required this.onDiscountVoucherRemoved,
    required this.onShippingVoucherRemoved,
  });

  @override
  State<_VoucherBottomSheet> createState() => _VoucherBottomSheetState();
}

class _VoucherBottomSheetState extends State<_VoucherBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _discountVouchers = [];
  List<Map<String, dynamic>> _shippingVouchers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVouchers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVouchers() async {
    try {
      final voucherProvider = context.read<VoucherProvider>();
      await voucherProvider.loadActiveVouchers();
      setState(() {
        _discountVouchers = voucherProvider.discountVouchers;
        _shippingVouchers = voucherProvider.shippingVouchers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatMoney(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return '${value.toInt()}đ';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.local_offer_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Chọn Voucher',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.percent, size: 16),
                        SizedBox(width: 6),
                        Text('Giảm giá'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_shipping, size: 16),
                        SizedBox(width: 6),
                        Text('Freeship'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: colorScheme.outlineVariant),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildVoucherList(_discountVouchers, 'discount'),
                  _buildVoucherList(_shippingVouchers, 'shipping'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherList(List<Map<String, dynamic>> vouchers, String type) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
            ),
            const SizedBox(height: 12),
            Text('Đang tải voucher...', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
          ],
        ),
      );
    }
    if (vouchers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'shipping' ? Icons.local_shipping_outlined : Icons.percent_outlined,
              size: 60,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              type == 'shipping' ? 'Không có mã freeship' : 'Không có mã giảm giá',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vouchers.length,
      itemBuilder: (context, index) => _buildVoucherItem(vouchers[index], type),
    );
  }

  Widget _buildVoucherItem(Map<String, dynamic> voucher, String type) {
    final colorScheme = Theme.of(context).colorScheme;
    final discountType = voucher['discount_type'] ?? '';
    final discountValue = (voucher['discount_value'] as num?)?.toDouble() ?? 0;
    final minOrder = (voucher['min_order_value'] as num?)?.toDouble() ?? 0;
    final code = voucher['code'] ?? '';
    final name = voucher['name'] ?? '';
    final quantity = voucher['quantity'] as int? ?? 0;
    final usedCount = voucher['used_count'] as int? ?? 0;
    final endDate = voucher['end_date'] as int?;
    final isNoExpiry = endDate == null;
    final isUsageExhausted = usedCount >= quantity;
    final isExpired = !isNoExpiry && DateTime.now().millisecondsSinceEpoch > endDate;
    final isDisabled = isUsageExhausted || isExpired;
    final isShipping = type == 'shipping';
    final isEligible = widget.subTotal >= minOrder;
    final isApplied = isShipping
        ? (widget.appliedShippingVoucher?['code'] as String?) == code
        : (widget.appliedDiscountVoucher?['code'] as String?) == code;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isApplied
              ? (isShipping ? Colors.blue.withValues(alpha: 0.15) : AppColors.primaryLight.withValues(alpha: 0.2))
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isApplied
                ? (isShipping ? Colors.blue : AppColors.primary)
                : (isDisabled ? colorScheme.outlineVariant : (isShipping ? Colors.blue : Colors.orange)),
            width: isApplied ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 85,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isShipping
                      ? [const Color(0xFF3498db), const Color(0xFF2980b9)]
                      : [const Color(0xFFe67e22), const Color(0xFFd35400)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isShipping)
                    const Icon(Icons.local_shipping, color: Colors.white, size: 26)
                  else
                    Text(
                      discountType == 'percent'
                          ? '${discountValue.toInt()}%'
                          : '${(discountValue / 1000).toStringAsFixed(0)}K',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    isShipping ? 'Freeship' : 'GIẢM',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(color: colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      !isEligible
                          ? 'Cần đơn tối thiểu ${_formatMoney(minOrder)}'
                          : (minOrder > 0 ? 'Tối thiểu ${_formatMoney(minOrder)}' : ''),
                      style: TextStyle(
                        color: !isEligible ? Colors.red[400] : colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _buildActionButton(
                context: context,
                isDisabled: isDisabled,
                isApplied: isApplied,
                isShipping: isShipping,
                isEligible: isEligible,
                voucher: voucher,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required bool isDisabled,
    required bool isApplied,
    required bool isShipping,
    required bool isEligible,
    required Map<String, dynamic> voucher,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    if (isDisabled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'Hết lượt',
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      );
    }
    if (isApplied) {
      return TextButton(
        onPressed: () {
          if (isShipping) {
            widget.onShippingVoucherRemoved();
          } else {
            widget.onDiscountVoucherRemoved();
          }
        },
        style: TextButton.styleFrom(
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
        child: const Text(
          'Bỏ chọn',
          style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      );
    }
    return ElevatedButton(
      onPressed: isEligible
          ? () {
              if (isShipping) {
                widget.onShippingVoucherSelected(voucher);
              } else {
                widget.onDiscountVoucherSelected(voucher);
              }
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isShipping ? Colors.blue : AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        elevation: 0,
      ),
      child: const Text(
        'Áp dụng',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ==================== SHIMMER ====================
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
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [const Color(0xFF2C2C2C), const Color(0xFF3C3C3C), const Color(0xFF2C2C2C)]
                  : [const Color(0xFFE6E6E6), const Color(0xFFF5F5F5), const Color(0xFFE6E6E6)],
            ),
          ),
        );
      },
    );
  }
}
