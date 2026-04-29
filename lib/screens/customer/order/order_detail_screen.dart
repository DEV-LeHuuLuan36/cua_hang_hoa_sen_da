import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/theme_helper.dart';
import '../../../providers/order_provider.dart';

class OrderDetailScreen extends StatefulWidget {
  final String? orderId;

  const OrderDetailScreen({Key? key, this.orderId}) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String? id = widget.orderId ?? ModalRoute.of(context)?.settings.arguments as String?;
      if (id != null) {
        context.read<OrderProvider>().loadOrderDetail(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: ThemeHelper.background(context),
      appBar: AppBar(
        title: Text(
          'Chi tiết đơn hàng',
          style: TextStyle(color: ThemeHelper.textPrimary(context)),
        ),
        backgroundColor: ThemeHelper.surface(context),
        elevation: 0,
        iconTheme: IconThemeData(color: ThemeHelper.textPrimary(context)),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator(color: isDark ? AppColors.primary : AppColors.primary));
          }

          final order = provider.currentOrder;
          final items = provider.currentOrderItems;

          if (order == null) {
            return Center(child: Text('Không tìm thấy đơn hàng!', style: TextStyle(color: ThemeHelper.textPrimary(context))));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Trạng thái đơn hàng
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ThemeHelper.surface(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mã ĐH: #${order['order_number']}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ThemeHelper.textPrimary(context)),
                          ),
                          Text(
                              order['order_status'] == 'PENDING' ? 'CHỜ XÁC NHẬN' :
                              order['order_status'] == 'SHIPPING' ? 'ĐANG GIAO' : 'HOÀN THÀNH',
                              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)
                          ),
                        ],
                      ),
                      Divider(height: 24, color: ThemeHelper.divider(context)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildTimelineItem(Icons.receipt_long, 'Đã đặt', true, isDark),
                          _buildTimelineDivider(true, isDark),
                          _buildTimelineItem(Icons.inventory_2, 'Chuẩn bị', order['order_status'] != 'PENDING', isDark),
                          _buildTimelineDivider(order['order_status'] != 'PENDING', isDark),
                          _buildTimelineItem(Icons.local_shipping, 'Đang giao', order['order_status'] == 'SHIPPING' || order['order_status'] == 'DELIVERED', isDark),
                          _buildTimelineDivider(order['order_status'] == 'DELIVERED', isDark),
                          _buildTimelineItem(Icons.check_circle, 'Đã nhận', order['order_status'] == 'DELIVERED', isDark),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Danh sách sản phẩm
                Text(
                  'Sản phẩm đã mua',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ThemeHelper.textPrimary(context)),
                ),
                const SizedBox(height: 8),
                ...items.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ThemeHelper.surface(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.eco, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['product_name'] ?? 'Sản phẩm',
                              style: TextStyle(fontWeight: FontWeight.bold, color: ThemeHelper.textPrimary(context)),
                            ),
                            Text(
                              'x${item['quantity']}',
                              style: TextStyle(color: ThemeHelper.textSecondary(context)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                const SizedBox(height: 16),

                // 3. Tổng kết
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ThemeHelper.surface(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tạm tính', style: TextStyle(color: ThemeHelper.textSecondary(context))),
                          Text('${order['subtotal']}đ', style: TextStyle(color: ThemeHelper.textPrimary(context))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Phí vận chuyển', style: TextStyle(color: ThemeHelper.textSecondary(context))),
                          Text('${order['shipping_fee']}đ', style: TextStyle(color: ThemeHelper.textPrimary(context))),
                        ],
                      ),
                      Divider(height: 24, color: ThemeHelper.divider(context)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ThemeHelper.textPrimary(context))),
                          Text('${order['total']}đ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primaryDark)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('QUAY LẠI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(IconData icon, String label, bool isDone, bool isDark) {
    final inactiveColor = isDark ? AppColors.darkBorder : Colors.grey.shade300;
    final activeColor = AppColors.primary;
    
    return Column(
      children: [
        Icon(icon, color: isDone ? activeColor : inactiveColor, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDone ? activeColor : (isDark ? AppColors.darkTextSecondary : Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineDivider(bool isDone, bool isDark) {
    final inactiveColor = isDark ? AppColors.darkBorder : Colors.grey.shade300;
    
    return Expanded(
      child: Container(
        height: 2,
        color: isDone ? AppColors.primary : inactiveColor,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
      ),
    );
  }
}
