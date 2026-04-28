import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product/succulent.dart';
import '../../theme/app_colors.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/auth_provider.dart';
import 'pressable_scale.dart';

class ProductCard extends StatelessWidget {
  final Succulent product;
  final VoidCallback? onTap;
  final bool enablePressScale;
  final double pressedScale;

  const ProductCard({
    Key? key,
    required this.product,
    this.onTap,
    this.enablePressScale = true,
    this.pressedScale = 0.95,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Gọi Provider để theo dõi trạng thái yêu thích
    final favoriteProvider = context.watch<FavoriteProvider>();
    final authProvider = context.read<AuthProvider>();

    // Kiểm tra xem sản phẩm này có đang nằm trong danh sách yêu thích không
    final isLiked = favoriteProvider.isFavorite(product.id);

    final card = Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sử dụng Stack để đè nút tim lên hình ảnh
              Expanded(
                child: Stack(
                  children: [
                    // 1. Ảnh sản phẩm hoặc Placeholder
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: product.primaryImage != null && product.primaryImage!.isNotEmpty
                            ? Image.asset(
                                product.primaryImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(Icons.image, size: 40, color: Colors.grey),
                                  ),
                                ),
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.image, size: 40, color: Colors.grey),
                                ),
                              ),
                      ),
                    ),

                    // 2. Nút Thả tim góc phải trên
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          final userId = authProvider.currentUser?.id;
                          if (userId != null) {
                            // Gọi hàm thêm/xóa khỏi Wishlist
                            favoriteProvider.toggleFavorite(userId, product);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vui lòng đăng nhập để lưu yêu thích!')),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.grey,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    // 3. Nhãn HẾT HÀNG
                    if (product.stock <= 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'HẾT HÀNG',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Thông tin sản phẩm
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.price.toStringAsFixed(0)} VNĐ',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!enablePressScale) return card;

    return PressableScale(
      pressedScale: pressedScale,
      child: card,
    );
  }
}