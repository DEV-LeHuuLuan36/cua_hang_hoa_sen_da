import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/constants/route_names.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../models/common/address.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Trạng thái Phương thức thanh toán
  String _selectedPaymentMethod = 'COD';

  // Trạng thái Voucher, Phí & Địa chỉ
  Map<String, dynamic>? _selectedVoucher;
  bool _isAutoFreeshipApplied = false;
  double _shippingFee = 30000;
  double _discountAmount = 0;
  double _subTotal = 0;
  Address? _selectedAddress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateInitialTotals();
    });
  }

  // ĐÓNG NGOẶC CHUẨN Ở ĐÂY
  void _calculateInitialTotals() async {
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

    // Tính tổng tiền dựa trên số lượng trong giỏ và giá bên bảng Product
    double calculatedSubTotal = 0;
    for (var item in cartProvider.cartItems) {
      try {
        final product = productProvider.products.firstWhere((p) => p.id == item.productId);
        calculatedSubTotal += product.price * item.quantity;
      } catch (e) {
        // Bỏ qua nếu không tìm thấy
      }
    }

    setState(() {
      _subTotal = calculatedSubTotal;
      _checkAutoVoucher();
    });
  }

  // CÁC HÀM NÀY PHẢI NẰM NGOÀI _calculateInitialTotals
  void _checkAutoVoucher() {
    final today = DateTime.now();
    if (today.day == today.month) {
      setState(() {
        _isAutoFreeshipApplied = true;
        _shippingFee = 0;
      });
    } else {
      setState(() {
        _isAutoFreeshipApplied = false;
        _shippingFee = 30000;
      });
    }
  }

  void _applyVoucher(Map<String, dynamic>? voucher) {
    setState(() {
      _selectedVoucher = voucher;
      _discountAmount = 0;
      _shippingFee = 30000;

      if (voucher == null) {
        _checkAutoVoucher();
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
          double calculated = (_subTotal * value / 100);
          if (maxDiscount != null && calculated > maxDiscount) {
            _discountAmount = maxDiscount;
          } else {
            _discountAmount = calculated;
          }
          break;
        case 'fixed':
          _discountAmount = value;
          break;
        default:
          _discountAmount = 0;
      }
    });
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
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ĐỊA CHỈ NHẬN HÀNG
            const Text('Địa chỉ nhận hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final selected = await Navigator.pushNamed(context, RouteNames.addressBook);
                if (selected != null && selected is Address) {
                  setState(() {
                    _selectedAddress = selected;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _selectedAddress == null
                          ? const Text('Vui lòng thêm địa chỉ nhận hàng', style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic))
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_selectedAddress!.fullName} - ${_selectedAddress!.phone}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${_selectedAddress!.addressLine}, ${_selectedAddress!.ward}, ${_selectedAddress!.district}, ${_selectedAddress!.city}', style: const TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. KHUYẾN MÃI / VOUCHER
            const Text('Khuyến mãi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.local_offer, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('Mã giảm giá', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      TextButton(
                        onPressed: () async {
                          final result = await Navigator.pushNamed(context, RouteNames.myVouchers);
                          if (result != null && result is Map<String, dynamic>) {
                            _applyVoucher(result);
                          }
                        },
                        child: Text(_selectedVoucher != null ? 'Thay đổi' : 'Chọn mã khác'),
                      )
                    ],
                  ),
                  if (_selectedVoucher != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.confirmation_number, color: Colors.blue, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Đã áp dụng mã: ${_selectedVoucher!['code']}',
                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
                            onPressed: () => _applyVoucher(null),
                          )
                        ],
                      ),
                    ),
                  if (_isAutoFreeshipApplied)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          SizedBox(width: 8),
                          Expanded(child: Text('Tự động áp dụng: Freeship Ngày Đôi', style: TextStyle(color: Colors.green, fontSize: 13))),
                        ],
                      ),
                    )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. PHƯƠNG THỨC THANH TOÁN
            const Text('Phương thức thanh toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'COD',
                    groupValue: _selectedPaymentMethod,
                    activeColor: AppColors.primary,
                    title: const Text('Thanh toán khi nhận hàng (COD)'),
                    onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    value: 'BANKING',
                    groupValue: _selectedPaymentMethod,
                    activeColor: AppColors.primary,
                    title: const Text('Chuyển khoản Ngân hàng (Thanh toán trước)'),
                    onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. TỔNG KẾT TIỀN
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Tạm tính'),
                    Text('${_subTotal.toInt()}đ')
                  ]),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Phí giao hàng'),
                    Text(_shippingFee == 0 ? 'Miễn phí' : '${_shippingFee.toInt()}đ',
                        style: TextStyle(color: _shippingFee == 0 ? Colors.green : AppColors.textPrimary))
                  ]),
                  if (_discountAmount > 0) ...[
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Giảm giá voucher'),
                      Text('-${_discountAmount.toInt()}đ', style: const TextStyle(color: Colors.red))
                    ]),
                  ],
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${totalAmount.toInt()}đ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primaryDark)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
            onPressed: () async {
              // CHẶN THANH TOÁN NẾU CHƯA CÓ ĐỊA CHỈ
              if (_selectedAddress == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Vui lòng chọn hoặc thêm địa chỉ nhận hàng trước khi thanh toán!'),
                  backgroundColor: Colors.red,
                ));
                return;
              }

              final authProvider = context.read<AuthProvider>();
              final cartProvider = context.read<CartProvider>();
              final orderProvider = context.read<OrderProvider>();

              final userId = authProvider.currentUser?.id;
              final cart = cartProvider.cart;

              if (userId == null || cart == null || items.isEmpty) return;

              // GỬI DATA KÈM ID ĐỊA CHỈ THẬT
              final success = await orderProvider.placeOrder(
                userId: userId,
                cartId: cart.id,
                cartItems: items.map((e) => {'product_id': e.productId, 'quantity': e.quantity}).toList(),
                totalAmount: totalAmount,
                voucherId: _selectedVoucher?['id'],
                discountAmount: _discountAmount,
                shippingFee: _shippingFee,
                paymentMethod: _selectedPaymentMethod,
                addressId: _selectedAddress!.id, // <--- Đã sửa ở đây
              );

              if (success && context.mounted) {
                await cartProvider.loadCart(userId);
                await orderProvider.loadMyOrders(userId);

                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Icon(Icons.check_circle, color: AppColors.success, size: 60),
                    content: const Text('Đặt hàng thành công!', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pushReplacementNamed(context, RouteNames.orderList);
                        },
                        child: const Text('XEM ĐƠN HÀNG', style: TextStyle(color: AppColors.primary)),
                      )
                    ],
                  ),
                );
              }
            },
            child: const Text('ĐẶT HÀNG NGAY', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}