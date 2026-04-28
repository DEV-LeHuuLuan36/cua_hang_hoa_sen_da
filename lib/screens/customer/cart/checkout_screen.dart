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
import '../../../database/contracts/voucher_contract.dart';
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

  final VoucherDao _voucherDao = VoucherDao();
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _voucherController = TextEditingController();
  
  // Tab index cho Bottom Sheet voucher
  int _voucherBottomSheetTab = 0;
  
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
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _notificationService.initialize();
    _calculateInitialTotals();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = context.read<UserProvider>();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    if (userId != null && userProvider.addresses.isEmpty) {
      userProvider.loadUserAddresses(userId);
    }
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

  /// Áp dụng voucher - kiểm tra ngay lập tức
  Future<void> _applyVoucherByCode(String code) async {
    if (code.trim().isEmpty) {
      setState(() {
        _voucherError = 'Vui lòng nhập mã giảm giá';
      });
      return;
    }

    setState(() {
      _isApplyingVoucher = true;
      _voucherError = null;
    });

    try {
      // Validate voucher ngay lập tức
      final result = await _voucherDao.validateVoucher(
        code: code.trim(),
        totalAmount: _subTotal,
      );

      if (!result.isValid) {
        setState(() {
          _voucherError = result.errorMessage ?? 'Mã giảm giá không hợp lệ';
          _isApplyingVoucher = false;
        });
        return;
      }

      final voucher = result.voucher!;
      final voucherType = voucher[VoucherContract.colVoucherType] ?? 'discount';

      HapticFeedback.lightImpact();

      // Áp dụng voucher theo loại
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
            SnackBar(
              content: Text('Áp dụng mã ${voucher[VoucherContract.colCode]} - Freeship!'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        _applyDiscountVoucher(voucher);
        _voucherController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Áp dụng mã ${voucher[VoucherContract.colCode]} - Giảm giá!'),
              backgroundColor: AppColors.success,
            ),
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
    final today = DateTime.now();
    setState(() {
      _appliedDiscountVoucher = voucher;
      _discountAmount = 0;

      if (voucher == null) {
        return;
      }

      final String type = voucher[VoucherContract.colDiscountType] ?? '';
      final double value = (voucher[VoucherContract.colDiscountValue] as num?)?.toDouble() ?? 0;
      final double? maxDiscount = (voucher[VoucherContract.colMaxDiscount] as num?)?.toDouble();

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

  void _removeDiscountVoucher() {
    _applyDiscountVoucher(null);
  }

  void _removeShippingVoucher() {
    _applyShippingVoucher(null);
  }

  Future<void> _calculateInitialTotals() async {
    final cartProvider = context.read<CartProvider>();
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
        _shippingDiscountAmount = _shippingFeeDefault;
        _shippingFee = 0;
      } else {
        _isAutoFreeshipApplied = false;
      }
    });
  }

  void _showVoucherBottomSheet(BuildContext context) {
    _voucherBottomSheetTab = 0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _VoucherBottomSheet(
        subTotal: _subTotal,
        appliedDiscountVoucher: _appliedDiscountVoucher,
        appliedShippingVoucher: _appliedShippingVoucher,
        onDiscountVoucherSelected: (voucher) {
          HapticFeedback.lightImpact();
          _applyDiscountVoucher(voucher);
          setState(() {}); // Cập nhật màn hình cha
        },
        onShippingVoucherSelected: (voucher) {
          HapticFeedback.lightImpact();
          _applyShippingVoucher(voucher);
          setState(() {}); // Cập nhật màn hình cha
        },
        onDiscountVoucherRemoved: () {
          _removeDiscountVoucher();
          setState(() {}); // Cập nhật màn hình cha
        },
        onShippingVoucherRemoved: () {
          _removeShippingVoucher();
          setState(() {}); // Cập nhật màn hình cha
        },
        onTabChanged: (tab) {
          setState(() {
            _voucherBottomSheetTab = tab;
          });
        },
      ),
    );
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
          // TextField nhập mã voucher
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _voucherController,
                  decoration: InputDecoration(
                    hintText: 'Nhập mã giảm giá',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    errorText: _voucherError,
                    errorStyle: const TextStyle(fontSize: 12),
                    isDense: true,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  onSubmitted: (value) => _applyVoucherByCode(value),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isApplyingVoucher
                    ? null
                    : () => _applyVoucherByCode(_voucherController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isApplyingVoucher
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'ÁP DỤNG',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
          // Nút chọn voucher từ danh sách
          TextButton.icon(
            onPressed: () => _showVoucherBottomSheet(context),
            icon: const Icon(Icons.local_offer_rounded, size: 18),
            label: const Text('Chọn mã giảm giá'),
          ),
          
          // Hiển thị voucher giảm giá đã áp dụng
          if (_appliedDiscountVoucher != null)
            _buildAppliedVoucherChip(
              voucher: _appliedDiscountVoucher!,
              type: 'discount',
              onRemove: _removeDiscountVoucher,
            ),
          
          // Hiển thị voucher freeship đã áp dụng
          if (_appliedShippingVoucher != null)
            _buildAppliedVoucherChip(
              voucher: _appliedShippingVoucher!,
              type: 'shipping',
              onRemove: _removeShippingVoucher,
            ),
          
          // Thông báo freeship tự động
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue,
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

  Widget _buildAppliedVoucherChip({
    required Map<String, dynamic> voucher,
    required String type,
    required VoidCallback onRemove,
  }) {
    final code = voucher[VoucherContract.colCode] ?? '';
    final isShipping = type == 'shipping';
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isShipping 
            ? Colors.blue.withValues(alpha: 0.15)
            : AppColors.primaryLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isShipping ? Colors.blue : AppColors.primary,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isShipping ? Icons.local_shipping : Icons.percent,
            color: isShipping ? Colors.blue : AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isShipping 
                  ? 'Freeship: $code'
                  : 'Giảm giá: $code',
              style: TextStyle(
                color: isShipping ? Colors.blue : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(12),
            child: Icon(
              Icons.close_rounded, 
              color: isShipping ? Colors.blue : AppColors.textSecondary,
              size: 20,
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

  Widget _buildSummaryRow(BuildContext context, String label, String value, {Color? valueColor, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: isDiscount ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: valueColor ?? (isDiscount ? AppColors.error : AppColors.textPrimary),
                  fontWeight: FontWeight.w600,
                  decoration: isDiscount ? TextDecoration.none : null,
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
          // Dòng 1: Tạm tính (Tiền hàng)
          _buildSummaryRow(context, 'Tạm tính', _formatMoney(_subTotal)),
          
          // Dòng 2: Phí vận chuyển (Mặc định)
          _buildSummaryRow(
            context,
            'Phí vận chuyển',
            _formatMoney(_shippingFeeDefault),
            valueColor: _shippingFee == 0 ? Colors.grey : AppColors.textPrimary,
          ),
          
          // Dòng 3: Giảm giá hàng hóa (Trừ tiền nếu có mã discount)
          if (_discountAmount > 0)
            _buildSummaryRow(
              context,
              'Giảm giá hàng hóa',
              '-${_formatMoney(_discountAmount)}',
              valueColor: AppColors.error,
              isDiscount: true,
            ),
          
          // Dòng 4: Giảm phí vận chuyển (Trừ tiền nếu có mã shipping)
          if (_shippingDiscountAmount > 0)
            _buildSummaryRow(
              context,
              'Giảm phí vận chuyển',
              '-${_formatMoney(_shippingDiscountAmount)}',
              valueColor: Colors.blue,
              isDiscount: true,
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

    // Kiểm tra voucher giảm giá trước khi đặt hàng
    if (_appliedDiscountVoucher != null) {
      final voucherId = _appliedDiscountVoucher!['id'] as String?;
      if (voucherId != null) {
        final remaining = await _voucherDao.getRemainingUsage(voucherId);
        if (remaining <= 0) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Voucher giảm giá đã hết lượt sử dụng!'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
      }
    }

    // Kiểm tra voucher freeship trước khi đặt hàng
    if (_appliedShippingVoucher != null) {
      final voucherId = _appliedShippingVoucher!['id'] as String?;
      if (voucherId != null) {
        final remaining = await _voucherDao.getRemainingUsage(voucherId);
        if (remaining <= 0) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Voucher freeship đã hết lượt sử dụng!'),
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
      voucherId: _appliedDiscountVoucher?['id'],
      discountAmount: _discountAmount,
      shippingFee: _shippingFee,
      paymentMethod: _selectedPaymentMethod,
      addressId: _selectedAddress!.id,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      // Trừ usage limit của voucher giảm giá
      if (_appliedDiscountVoucher != null) {
        final voucherId = _appliedDiscountVoucher!['id'] as String?;
        if (voucherId != null) {
          await _voucherDao.decrementUsageLimit(voucherId);
        }
      }

      // Trừ usage limit của voucher freeship
      if (_appliedShippingVoucher != null) {
        final voucherId = _appliedShippingVoucher!['id'] as String?;
        if (voucherId != null) {
          await _voucherDao.decrementUsageLimit(voucherId);
        }
      }

      // Đẩy thông báo thành công
      await _notificationService.showOrderSuccess(
        title: 'Đặt hàng thành công! 🎉',
        body: 'Cảm ơn bạn đã mua sắm. Đơn hàng sen đá của bạn đang chờ xử lý.',
        payload: 'order_list',
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

    // Tính tổng tiền: Tạm tính + Phí ship - Giảm giá hàng hóa - Giảm phí ship
    double totalAmount = (_subTotal + _shippingFeeDefault - _discountAmount - _shippingDiscountAmount);
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

// ==================== VOUCHER BOTTOM SHEET ====================
class _VoucherBottomSheet extends StatefulWidget {
  final double subTotal;
  final Map<String, dynamic>? appliedDiscountVoucher;
  final Map<String, dynamic>? appliedShippingVoucher;
  final Function(Map<String, dynamic>) onDiscountVoucherSelected;
  final Function(Map<String, dynamic>) onShippingVoucherSelected;
  final VoidCallback onDiscountVoucherRemoved;
  final VoidCallback onShippingVoucherRemoved;
  final Function(int) onTabChanged;

  const _VoucherBottomSheet({
    required this.subTotal,
    this.appliedDiscountVoucher,
    this.appliedShippingVoucher,
    required this.onDiscountVoucherSelected,
    required this.onShippingVoucherSelected,
    required this.onDiscountVoucherRemoved,
    required this.onShippingVoucherRemoved,
    required this.onTabChanged,
  });

  @override
  State<_VoucherBottomSheet> createState() => _VoucherBottomSheetState();
}

class _VoucherBottomSheetState extends State<_VoucherBottomSheet> with SingleTickerProviderStateMixin {
  final VoucherDao _voucherDao = VoucherDao();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _discountVouchers = [];
  List<Map<String, dynamic>> _shippingVouchers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        widget.onTabChanged(_tabController.index);
      }
    });
    _loadVouchers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVouchers() async {
    try {
      final discountVouchers = await _voucherDao.getActiveDiscountVouchers();
      final shippingVouchers = await _voucherDao.getActiveShippingVouchers();
      setState(() {
        _discountVouchers = discountVouchers;
        _shippingVouchers = shippingVouchers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Chọn Voucher',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Tab bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
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
              const Divider(height: 1),
              // Voucher lists
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildVoucherList(_discountVouchers, 'discount', setModalState),
                    _buildVoucherList(_shippingVouchers, 'shipping', setModalState),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherList(List<Map<String, dynamic>> vouchers, String type, StateSetter setModalState) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vouchers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'shipping' ? Icons.local_shipping_outlined : Icons.percent_outlined,
              size: 60,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              type == 'shipping' ? 'Không có mã freeship' : 'Không có mã giảm giá',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vouchers.length,
      itemBuilder: (context, index) {
        final voucher = vouchers[index];
        return _buildVoucherItem(voucher, type, setModalState);
      },
    );
  }

  Widget _buildVoucherItem(Map<String, dynamic> voucher, String type, StateSetter setModalState) {
    final discountType = voucher[VoucherContract.colDiscountType] ?? '';
    final discountValue = (voucher[VoucherContract.colDiscountValue] as num?)?.toDouble() ?? 0;
    final minOrder = (voucher[VoucherContract.colMinOrderValue] as num?)?.toDouble() ?? 0;
    final code = voucher[VoucherContract.colCode] ?? '';
    final name = voucher[VoucherContract.colName] ?? '';
    final quantity = voucher[VoucherContract.colQuantity] as int? ?? 0;
    final usedCount = voucher[VoucherContract.colUsedCount] as int? ?? 0;
    final endDate = voucher[VoucherContract.colEndDate] as int?;
    final isNoExpiry = endDate == null;
    final isUsageExhausted = usedCount >= quantity;
    final isExpired = !isNoExpiry && DateTime.now().millisecondsSinceEpoch > endDate;
    final isDisabled = isUsageExhausted || isExpired;
    final isShipping = type == 'shipping';
    final isEligible = widget.subTotal >= minOrder;
    
    final isApplied = isShipping
        ? (widget.appliedShippingVoucher?[VoucherContract.colCode] as String?) == code
        : (widget.appliedDiscountVoucher?[VoucherContract.colCode] as String?) == code;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isApplied ? (isShipping ? Colors.blue[50] : AppColors.primaryLight.withValues(alpha: 0.2)) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isApplied 
                ? (isShipping ? Colors.blue : AppColors.primary)
                : (isDisabled ? Colors.grey[300]! : (isShipping ? Colors.blue[200]! : Colors.orange[200]!)),
            width: isApplied ? 2 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Left side
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        isShipping ? 'Freeship' : 'GIẢM',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Right side
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isShipping ? Colors.blue : Colors.orange).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  code,
                                  style: TextStyle(
                                    color: isShipping ? Colors.blue : Colors.orange[700],
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
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text(
                                    'HẾT LƯỢT',
                                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            if (isExpired) ...[
                              const SizedBox(width: 4),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text(
                                    'HẾT HẠN',
                                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        if (!isEligible)
                          Text(
                            'Cần đơn tối thiểu ${_formatMoney(minOrder)}',
                            style: TextStyle(
                              color: Colors.red[400],
                              fontSize: 10,
                            ),
                          )
                        else if (minOrder > 0)
                          Text(
                            'Tối thiểu ${_formatMoney(minOrder)}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Action
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: isDisabled
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isUsageExhausted ? 'Hết lượt' : 'Hết hạn',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : isApplied
                          ? TextButton(
                              onPressed: () {
                                if (isShipping) {
                                  widget.onShippingVoucherRemoved();
                                } else {
                                  widget.onDiscountVoucherRemoved();
                                }
                                setModalState(() {}); // Cập nhật UI bottom sheet ngay
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.red[50],
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                              child: const Text(
                                'Bỏ chọn',
                                style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: isEligible
                                  ? () {
                                      if (isShipping) {
                                        widget.onShippingVoucherSelected(voucher);
                                      } else {
                                        widget.onDiscountVoucherSelected(voucher);
                                      }
                                      setModalState(() {}); // Cập nhật UI bottom sheet ngay
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isShipping ? Colors.blue : AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Áp dụng',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatMoney(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return '${value.toInt()}đ';
  }
}

// ==================== SHIMMER & DIALOG ====================
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
