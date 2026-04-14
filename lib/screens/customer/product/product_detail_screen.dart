import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/product_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../models/cart/cart_item.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/constants/route_names.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId; // Chỉ nhận ID theo đúng chuẩn quy tắc điều hướng

  const ProductDetailScreen({Key? key, required this.productId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Tìm sản phẩm trong danh sách dựa trên ID
    final productProvider = context.watch<ProductProvider>();
    final product = productProvider.products.cast().firstWhere(
          (p) => p.id == productId,
      orElse: () => null,
    );

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi')),
        body: const Center(child: Text('Không tìm thấy sản phẩm!')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              // Sẽ code thêm vào mục Yêu thích sau
            },
          ),
        ],
      ),
      // Cho phép body tràn lên trên AppBar để làm ảnh full màn hình đẹp hơn
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ảnh sản phẩm (Tạm dùng khối màu xanh lá)
            Container(
              width: double.infinity,
              height: 350,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: const SafeArea(
                child: Center(
                  child: Icon(Icons.eco, size: 120, color: AppColors.primary),
                ),
              ),
            ),

            // 2. Thông tin chính
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                      Text(
                        '${product.price.toStringAsFixed(0)}đ',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.accent, size: 20),
                      const SizedBox(width: 4),
                      Text('${product.rating} (${product.reviewCount} đánh giá)', style: const TextStyle(color: AppColors.textSecondary)),
                      const Spacer(),
                      Text('Kho: ${product.stock}', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. Mô tả sản phẩm
                  const Text('Mô tả sản phẩm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    product.description ?? 'Chưa có mô tả cho sản phẩm này.',
                    style: const TextStyle(height: 1.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  // 4. Hướng dẫn chăm sóc (Lấy từ class CareInstruction)
                  const Text('Hướng dẫn chăm sóc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (product.careInstruction != null) ...[
                    _buildCareItem(Icons.wb_sunny_outlined, 'Ánh sáng', product.careInstruction!.lightRequirement),
                    _buildCareItem(Icons.water_drop_outlined, 'Lượng nước', product.careInstruction!.waterRequirement),
                    _buildCareItem(Icons.thermostat_outlined, 'Độ khó', product.careInstruction!.careLevel),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),

      // 5. Thanh Bottom Navigation chứa nút Thêm vào giỏ hàng
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.primary),
                  onPressed: () {
                    Navigator.pushNamed(context, RouteNames.cart);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    // Logic Thêm vào giỏ hàng
                    final user = context.read<AuthProvider>().currentUser;
                    if (user == null) return;

                    final cartProvider = context.read<CartProvider>();
                    // Phải đảm bảo giỏ hàng đã được load
                    if (cartProvider.cart == null) {
                      await cartProvider.loadCart(user.id);
                    }

                    final cartId = cartProvider.cart?.id ?? '';
                    final newItem = CartItem(
                      id: 'ci_${DateTime.now().millisecondsSinceEpoch}',
                      cartId: cartId,
                      productId: product.id,
                      quantity: 1,
                      addedAt: DateTime.now().millisecondsSinceEpoch,
                    );

                    final success = await cartProvider.addToCart(newItem);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm vào giỏ hàng!'), backgroundColor: AppColors.success));
                    }
                  },
                  child: const Text('THÊM VÀO GIỎ HÀNG', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget con hỗ trợ hiển thị icon chăm sóc
  Widget _buildCareItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primaryLight.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}