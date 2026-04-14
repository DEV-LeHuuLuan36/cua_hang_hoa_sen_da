import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_colors.dart';

class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({Key? key}) : super(key: key);

  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> {
  @override
  void initState() {
    super.initState();
    // Yêu cầu tải toàn bộ đơn hàng khi vừa vào trang
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadAllOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Quản lý Đơn hàng', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Cần xử lý'),
              Tab(text: 'Đang giao'),
              Tab(text: 'Hoàn thành'),
            ],
          ),
        ),
        body: Consumer<OrderProvider>(
          builder: (context, orderProvider, child) {
            if (orderProvider.isLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            final allOrders = orderProvider.allOrders;

            return TabBarView(
              children: [
                _buildOrderList(allOrders, 'PENDING', 'Chờ xác nhận', AppColors.warning, context),
                _buildOrderList(allOrders, 'SHIPPING', 'Đang giao', Colors.blue, context),
                _buildOrderList(allOrders, 'DELIVERED', 'Hoàn thành', AppColors.success, context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders, String statusKey, String statusLabel, Color color, BuildContext context) {
    // Lọc đơn hàng theo trạng thái tương ứng với từng Tab
    final filteredOrders = orders.where((o) => o['order_status'] == statusKey).toList();

    if (filteredOrders.isEmpty) {
      return const Center(child: Text('Không có đơn hàng nào.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        final orderId = order['id'];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ĐH: #${order['order_number']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(statusLabel, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const Divider(),
                const Text('Khách hàng: Nguyễn Văn Khách'), // Tạm fix cứng tên, tương lai sẽ Join với user
                Text('Ngày đặt: ${DateTime.fromMillisecondsSinceEpoch(order['created_at']).toString().substring(0, 16)}'),
                Text('Tổng tiền: ${order['total']}đ', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),

                // HIỂN THỊ NÚT THAO TÁC NẾU LÀ TAB "CẦN XỬ LÝ"
                if (statusKey == 'PENDING') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                          onPressed: () {
                            context.read<OrderProvider>().updateOrderStatus(orderId, 'CANCELLED');
                          },
                          child: const Text('HỦY ĐƠN'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                          onPressed: () {
                            // CHUYỂN TRẠNG THÁI SANG ĐANG GIAO
                            context.read<OrderProvider>().updateOrderStatus(orderId, 'SHIPPING');
                          },
                          child: const Text('XÁC NHẬN'),
                        ),
                      ),
                    ],
                  )
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}