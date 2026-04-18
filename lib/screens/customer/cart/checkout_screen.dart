import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/constants/route_names.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/product_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Trạng thái Phương thức thanh toán
  String _selectedPaymentMethod = 'COD';

  // Trạng thái Voucher & Phí
  Map<String, dynamic>? _selectedVoucher; // Voucher chọn thủ công
  bool _isAutoFreeshipApplied = false;   // Cờ kiểm tra ngày đôi
  double _shippingFee = 30000;           // Phí ship mặc định
  double _discountAmount = 0;            // Số tiền được giảm
  double _subTotal = 0;                  // Tổng tiền hàng thực tế

  @override
  void initState() {
    super.initState();
    // Khởi tạo dữ liệu sau khi frame đầu tiên được vẽ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateInitialTotals();
    });
  }

  void _calculateInitialTotals() {
    final cartProvider = context.read<CartProvider>();
    final productProvider = context.read<ProductProvider>();

    // Tính tổng tiền dựa trên số lượng trong giỏ và giá bên bảng Product
    double calculatedSubTotal = 0;
    for (var item in cartProvider.cartItems) {
      try {
        final product = productProvider.products.firstWhere((p) => p.id == item.productId);
        calculatedSubTotal += product.price * item.quantity;
      } catch (e) {
        // Bỏ qua nếu không tìm thấy thông tin sản phẩm
      }
    }

    setState(() {
      _subTotal = calculatedSubTotal; // Đã bỏ 'cartProvider.totalAmount' bị lỗi
      _checkAutoVoucher();
    });
  }

  // Logic kiểm tra Voucher tự động: Tháng trùng Ngày (VD: 9/9, 10/10)
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

  // Hàm tính toán và áp dụng Voucher
  void _applyVoucher(Map<String, dynamic>? voucher) {
    setState(() {
      _selectedVoucher = voucher;
      _discountAmount = 0;
      _shippingFee = 30000; // Reset phí ship về mặc định

      if (voucher == null) {
        // Nếu xóa voucher thủ công, quay lại kiểm tra ngày đôi
        _checkAutoVoucher();
        return;
      }

      // Nếu có chọn voucher thủ công, tắt chế độ tự động Freeship ngày đôi
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
          // Không vượt quá mức giảm tối đa nếu có
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

    // Tính tổng tiền cuối cùng (đảm bảo không âm)
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
            // 1. Địa chỉ giao hàng (Tạm thời giữ UI cũ của bạn)
            const Text('Địa chỉ nhận hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.location_on, color: AppColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nguyễn Văn A - 0901234567', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Số 123 Đường ABC, Quận 1, TP. HCM', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Khuyến mãi / Voucher
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
                          // Chờ kết quả trả về từ màn hình chọn Voucher
                          final result = await Navigator.pushNamed(context, RouteNames.myVouchers);
                          if (result != null && result is Map<String, dynamic>) {
                            _applyVoucher(result);
                          }
                        },
                        child: Text(_selectedVoucher != null ? 'Thay đổi' : 'Chọn mã khác'),
                      )
                    ],
                  ),

                  // Hiển thị Voucher đã chọn thủ công
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

                  // Hiển thị Freeship tự động (chỉ hiện khi không có voucher thủ công)
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

            // 3. Phương thức thanh toán
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

            // 4. Tổng kết tiền
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
                    Text(
                        _shippingFee == 0 ? 'Miễn phí' : '${_shippingFee.toInt()}đ',
                        style: TextStyle(color: _shippingFee == 0 ? Colors.green : AppColors.textPrimary)
                    )
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
              final authProvider = context.read<AuthProvider>();
              final cartProvider = context.read<CartProvider>();
              final orderProvider = context.read<OrderProvider>();

              final userId = authProvider.currentUser?.id;
              final cart = cartProvider.cart;

              if (userId == null || cart == null || items.isEmpty) return;

              // Truyền toàn bộ dữ liệu tính toán thực tế vào Provider
              final success = await orderProvider.placeOrder(
                userId: userId,
                cartId: cart.id,
                cartItems: items.map((e) => {'product_id': e.productId, 'quantity': e.quantity}).toList(),
                totalAmount: totalAmount,
                voucherId: _selectedVoucher?['id'],
                discountAmount: _discountAmount,
                shippingFee: _shippingFee,
                paymentMethod: _selectedPaymentMethod,
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