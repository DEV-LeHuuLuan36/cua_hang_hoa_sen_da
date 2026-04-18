import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/constants/route_names.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final productProvider = context.read<ProductProvider>();
    final cartItems = cartProvider.cartItems;

    // Tính tổng tiền giỏ hàng
    double totalAmount = 0;
    for (var item in cartItems) {
      final product = productProvider.products.firstWhere(
            (p) => p.id == item.productId,
        // Nếu không tìm thấy, trả về một sản phẩm giả để tránh lỗi crash app
        orElse: () => productProvider.products.first,
      );
      totalAmount += product.price * item.quantity;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Giỏ hàng của bạn', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
        centerTitle: true,
      ),
      body: cartItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Giỏ hàng trống', style: TextStyle(fontSize: 20, color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, RouteNames.home, (route) => false);
              },
              child: const Text('TIẾP TỤC MUA SẮM', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                // Tìm thông tin gốc của sản phẩm
                final product = productProvider.products.firstWhere((p) => p.id == item.productId);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                  ),
                  child: Row(
                    children: [
                      // Ảnh giả (Placeholder)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.eco, color: AppColors.primary, size: 40),
                      ),
                      const SizedBox(width: 16),
                      // Thông tin
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('${product.price.toStringAsFixed(0)}đ', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            // Tăng giảm số lượng
                            Row(
                              children: [
                                _buildQuantityBtn(Icons.remove, () {
                                  cartProvider.updateItemQuantity(item.id, item.quantity - 1);
                                }),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                _buildQuantityBtn(Icons.add, () {
                                  cartProvider.updateItemQuantity(item.id, item.quantity + 1);
                                }),
                              ],
                            )
                          ],
                        ),
                      ),
                      // Nút xóa
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: () => cartProvider.removeItem(item.id),
                      )
                    ],
                  ),
                );
              },
            ),
          ),

          // Thanh tổng tiền & Thanh toán
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng cộng:', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                      Text('${totalAmount.toStringAsFixed(0)}đ', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        // Chuyển sang màn hình Xác nhận thanh toán (Checkout)
                        Navigator.pushNamed(context, RouteNames.checkout);
                      },
                      child: const Text('ĐẾN TRANG THANH TOÁN', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // Widget hỗ trợ vẽ nút +/-
  Widget _buildQuantityBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}