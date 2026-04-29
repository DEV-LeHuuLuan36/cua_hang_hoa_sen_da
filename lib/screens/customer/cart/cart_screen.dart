import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/constants/route_names.dart';
import '../../../utils/theme_helper.dart';
import '../../../widgets/common/pressable_scale.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final productProvider = context.read<ProductProvider>();
    final cartItems = cartProvider.cartItems;
    final selectedItemIds = cartProvider.selectedItemIds;

    // Tính tổng tiền chỉ từ các sản phẩm được chọn
    double totalAmount = 0;
    for (var item in cartProvider.selectedItems) {
      final product = productProvider.products.firstWhere(
        (p) => p.id == item.productId,
        orElse: () => productProvider.products.first,
      );
      totalAmount += product.price * item.quantity;
    }

    final isAllSelected = cartItems.isNotEmpty && selectedItemIds.length == cartItems.length;

    return Scaffold(
      backgroundColor: ThemeHelper.background(context),
      appBar: AppBar(
        title: Text('Giỏ hàng của bạn', style: TextStyle(color: ThemeHelper.textPrimary(context))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, RouteNames.home);
            }
          },
        ),
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: ThemeHelper.textSecondary(context)),
                  const SizedBox(height: 16),
                  Text('Giỏ hàng trống', style: TextStyle(fontSize: 20, color: ThemeHelper.textSecondary(context))),
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
                      final product = productProvider.products.firstWhere(
                        (p) => p.id == item.productId,
                        orElse: () => productProvider.products.first,
                      );
                      final isSelected = selectedItemIds.contains(item.id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: PressableScale(
                          pressedScale: 0.98,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryLight.withValues(alpha: 0.1)
                                  : ThemeHelper.surface(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Checkbox
                                Checkbox(
                                  value: isSelected,
                                  activeColor: AppColors.primary,
                                  onChanged: (_) => cartProvider.toggleSelectItem(item.id),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                // Hình ảnh sản phẩm
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: product.primaryImage != null && product.primaryImage!.isNotEmpty
                                      ? Image.asset(
                                          product.primaryImage!,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                                        )
                                      : _buildPlaceholder(),
                                ),
                                const SizedBox(width: 12),
                                // Thông tin
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: ThemeHelper.textPrimary(context),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${product.price.toStringAsFixed(0)}đ',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Tăng giảm số lượng
                                      Row(
                                        children: [
                                          _buildQuantityBtn(Icons.remove, () {
                                            if (item.quantity > 1) {
                                              cartProvider.updateItemQuantity(item.id, item.quantity - 1);
                                            }
                                          }, context),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            child: Text(
                                              '${item.quantity}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: ThemeHelper.textPrimary(context),
                                              ),
                                            ),
                                          ),
                                          _buildQuantityBtn(Icons.add, () {
                                            cartProvider.updateItemQuantity(item.id, item.quantity + 1);
                                          }, context),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                // Nút xóa
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                  onPressed: () {
                                    cartProvider.removeItem(item.id);
                                  },
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Thanh tổng tiền & Thanh toán
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ThemeHelper.surface(context),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Chọn tất cả
                        InkWell(
                          onTap: () {
                            if (isAllSelected) {
                              cartProvider.clearSelectedItems();
                            } else {
                              cartProvider.selectAllItems();
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isAllSelected,
                                  activeColor: AppColors.primary,
                                  onChanged: (_) {
                                    if (isAllSelected) {
                                      cartProvider.clearSelectedItems();
                                    } else {
                                      cartProvider.selectAllItems();
                                    }
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                Text(
                                  'Chọn tất cả',
                                  style: TextStyle(
                                    color: ThemeHelper.textPrimary(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                if (selectedItemIds.isNotEmpty)
                                  Text(
                                    'Đã chọn ${selectedItemIds.length} sản phẩm',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ThemeHelper.textSecondary(context),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Divider(color: ThemeHelper.divider(context)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tổng cộng:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: ThemeHelper.textSecondary(context),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${totalAmount.toStringAsFixed(0)}đ',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                ),
                                onPressed: () {
                                  if (selectedItemIds.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Vui lòng chọn ít nhất một sản phẩm để thanh toán!'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.pushNamed(context, RouteNames.checkout);
                                },
                                child: const Text(
                                  'THANH TOÁN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
    );
  }

  static Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.eco, color: AppColors.primary, size: 40),
    );
  }

  static Widget _buildQuantityBtn(IconData icon, VoidCallback onTap, BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: ThemeHelper.textSecondary(context).withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: ThemeHelper.textPrimary(context)),
      ),
    );
  }
}
