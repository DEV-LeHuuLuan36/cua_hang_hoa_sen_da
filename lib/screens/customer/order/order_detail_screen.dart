import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/order_provider.dart';

class OrderDetailScreen extends StatefulWidget {
  final String? orderId; // Nhận orderId từ arguments

  const OrderDetailScreen({Key? key, this.orderId}) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Đọc argument nếu không truyền qua constructor
      final String? id = widget.orderId ?? ModalRoute.of(context)?.settings.arguments as String?;
      if (id != null) {
        context.read<OrderProvider>().loadOrderDetail(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final order = provider.currentOrder;
          final items = provider.currentOrderItems;

          if (order == null) {
            return const Center(child: Text('Không tìm thấy đơn hàng!'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Trạng thái đơn hàng
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Mã ĐH: #${order['order_number']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                              order['order_status'] == 'PENDING' ? 'CHỜ XÁC NHẬN' :
                              order['order_status'] == 'SHIPPING' ? 'ĐANG GIAO' : 'HOÀN THÀNH',
                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildTimelineItem(Icons.receipt_long, 'Đã đặt', true),
                          _buildTimelineDivider(true),
                          _buildTimelineItem(Icons.inventory_2, 'Chuẩn bị', order['order_status'] != 'PENDING'),
                          _buildTimelineDivider(order['order_status'] != 'PENDING'),
                          _buildTimelineItem(Icons.local_shipping, 'Đang giao', order['order_status'] == 'SHIPPING' || order['order_status'] == 'DELIVERED'),
                          _buildTimelineDivider(order['order_status'] == 'DELIVERED'),
                          _buildTimelineItem(Icons.check_circle, 'Đã nhận', order['order_status'] == 'DELIVERED'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Danh sách sản phẩm (Lấy từ DB)
                const Text('Sản phẩm đã mua', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...items.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(color: AppColors.primaryLight.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.eco, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['product_name'] ?? 'Sản phẩm', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('x${item['quantity']}', style: const TextStyle(color: AppColors.textSecondary)),
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
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Tạm tính'), Text('${order['subtotal']}đ')]),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Phí vận chuyển'), Text('${order['shipping_fee']}đ')]),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildTimelineItem(IconData icon, String label, bool isDone) {
    return Column(
      children: [
        Icon(icon, color: isDone ? AppColors.primary : Colors.grey.shade300, size: 28),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: isDone ? AppColors.primary : Colors.grey)),
      ],
    );
  }

  Widget _buildTimelineDivider(bool isDone) {
    return Expanded(
      child: Container(
        height: 2,
        color: isDone ? AppColors.primary : Colors.grey.shade300,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
      ),
    );
  }
}