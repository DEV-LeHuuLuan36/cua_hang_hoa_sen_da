import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../models/cart/cart_item.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/constants/route_names.dart';
import '../../../utils/theme_helper.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId; // Chỉ nhận ID theo đúng chuẩn quy tắc điều hướng

  const ProductDetailScreen({Key? key, required this.productId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      backgroundColor: ThemeHelper.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.primaryDark),
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
            // 1. Ảnh sản phẩm (chất lượng cao)
            Hero(
              tag: 'product_image_${product.id}',
              child: Container(
                width: double.infinity,
                height: 350,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                  child: product.primaryImage != null && product.primaryImage!.isNotEmpty
                      ? Image.asset(
                          product.primaryImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0),
                            child: Center(
                              child: Icon(Icons.image, size: 80, color: ThemeHelper.icon(context)),
                            ),
                          ),
                        )
                      : Container(
                          color: isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0),
                          child: Center(
                            child: Icon(Icons.image, size: 80, color: ThemeHelper.icon(context)),
                          ),
                        ),
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
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ThemeHelper.textPrimary(context)),
                        ),
                      ),
                      Text(
                        '${product.price.toStringAsFixed(0)}đ',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Hiển thị star rating với độ chính xác (sao nguyên, nửa sao, sao rỗng)
                  _buildStarRating(product.rating, product.reviewCount, product.stock),
                  const SizedBox(height: 24),

                  // 3. Mô tả sản phẩm
                  const Text('Mô tả sản phẩm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    product.description ?? 'Chưa có mô tả cho sản phẩm này.',
                    style: TextStyle(height: 1.5, color: ThemeHelper.textSecondary(context)),
                  ),
                  const SizedBox(height: 24),

                  // 4. Hướng dẫn chăm sóc (Lấy từ class CareInstruction)
                  const Text('Hướng dẫn chăm sóc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (product.careInstruction != null) ...[
                    _buildCareItem(context, Icons.wb_sunny_outlined, 'Ánh sáng', product.careInstruction!.lightRequirement),
                    _buildCareItem(context, Icons.water_drop_outlined, 'Lượng nước', product.careInstruction!.waterRequirement),
                    _buildCareItem(context, Icons.thermostat_outlined, 'Độ khó', product.careInstruction!.careLevel),
                  ],
                  const SizedBox(height: 24),

                  // 5. Thông số kỹ thuật
                  const Text('Thông số kỹ thuật', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (product.size != null) _buildCareItem(context, Icons.straighten, 'Kích thước', product.size!),
                  if (product.color != null) _buildCareItem(context, Icons.palette, 'Màu sắc', product.color!),
                  if (product.origin != null) _buildCareItem(context, Icons.public, 'Xuất xứ', product.origin!),
                  if (product.sku != null) _buildCareItem(context, Icons.qr_code, 'Mã SKU', product.sku!),

                  // 6. Khu vực Xem tất cả đánh giá
                  const SizedBox(height: 24),
                  _buildReviewsSummary(context, product.rating, product.reviewCount, product.id),
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
          color: ThemeHelper.surface(context),
          boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
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
                    backgroundColor: product.stock > 0 ? AppColors.primary : ThemeHelper.icon(context),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: product.stock > 0 ? () async {
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
                  } : null,
                  child: Text(
                    product.stock > 0 ? 'THÊM VÀO GIỎ HÀNG' : 'HẾT HÀNG',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget hiển thị star rating với sao nguyên, nửa sao, sao rỗng
  Widget _buildStarRating(double rating, int reviewCount, int stock) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (reviewCount > 0) ...[
          // Hiển thị các ngôi sao
          ...List.generate(5, (index) {
            if (index < rating.floor()) {
              return const Icon(Icons.star, color: AppColors.accent, size: 20);
            } else if (index < rating) {
              return const Icon(Icons.star_half, color: AppColors.accent, size: 20);
            } else {
              return Icon(Icons.star_border, color: AppColors.accent.withOpacity(0.4), size: 20);
            }
          }),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${rating.toStringAsFixed(1)} ($reviewCount đánh giá)',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ] else ...[
          ...List.generate(5, (index) {
            return Icon(Icons.star_border, color: Colors.grey[400], size: 20);
          }),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Chưa có đánh giá nào',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: stock > 0 ? AppColors.success.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            stock > 0 ? 'Còn hàng' : 'Hết hàng',
            style: TextStyle(
              color: stock > 0 ? AppColors.success : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // Widget hiển thị khu vực Xem tất cả đánh giá
  Widget _buildReviewsSummary(BuildContext context, double rating, int reviewCount, String productId) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, RouteNames.allReviews, arguments: productId);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ThemeHelper.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Đánh giá sản phẩm ($reviewCount)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, RouteNames.allReviews, arguments: productId);
                  },
                  icon: const Icon(Icons.chevron_right, size: 20),
                  label: const Text('Xem tất cả', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (reviewCount > 0) ...[
              // Hiển thị số sao trung bình to rõ ràng
              Row(
                children: [
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.accent),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Các ngôi sao to
                      Row(
                        children: List.generate(5, (index) {
                          if (index < rating.floor()) {
                            return const Icon(Icons.star, color: AppColors.accent, size: 24);
                          } else if (index < rating) {
                            return const Icon(Icons.star_half, color: AppColors.accent, size: 24);
                          } else {
                            return Icon(Icons.star_border, color: AppColors.accent.withOpacity(0.4), size: 24);
                          }
                        }),
                      ),
                      Text(
                        '$reviewCount đánh giá',
                        style: TextStyle(color: ThemeHelper.textSecondary(context), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Chưa có đánh giá nào. Hãy là người đầu tiên đánh giá sản phẩm này!',
                style: TextStyle(color: ThemeHelper.textSecondary(context), fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Widget con hỗ trợ hiển thị icon chăm sóc
  Widget _buildCareItem(BuildContext context, IconData icon, String title, String value) {
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
          Text(title, style: TextStyle(color: ThemeHelper.textSecondary(context), fontSize: 16)),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ThemeHelper.textPrimary(context))),
        ],
      ),
    );
  }
}