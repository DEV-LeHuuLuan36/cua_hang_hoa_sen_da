import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/constants/route_names.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({Key? key}) : super(key: key);

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  @override
  void initState() {
    super.initState();
    // Tải danh sách đơn hàng của User đang đăng nhập
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<OrderProvider>().loadMyOrders(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Đơn hàng của tôi', style: TextStyle(color: AppColors.textPrimary)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Chờ xác nhận'),
              Tab(text: 'Đang giao'),
              Tab(text: 'Hoàn thành'),
              Tab(text: 'Đã hủy'),
            ],
          ),
        ),
        body: Consumer<OrderProvider>(
          builder: (context, orderProvider, child) {
            if (orderProvider.isLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            final myOrders = orderProvider.myOrders;

            return TabBarView(
              children: [
                _buildOrderList(myOrders, 'PENDING', AppColors.warning),
                _buildOrderList(myOrders, 'SHIPPING', Colors.blue),
                _buildOrderList(myOrders, 'DELIVERED', AppColors.success),
                _buildOrderList(myOrders, 'CANCELLED', AppColors.error),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders, String statusKey, Color statusColor) {
    final filteredOrders = orders.where((o) => o['order_status'] == statusKey).toList();

    if (filteredOrders.isEmpty) {
      return const Center(child: Text('Không có đơn hàng nào ở trạng thái này.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Mã ĐH: #${order['order_number']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    statusKey == 'PENDING' ? 'Chờ xác nhận' :
                    statusKey == 'SHIPPING' ? 'Đang giao' :
                    statusKey == 'DELIVERED' ? 'Hoàn thành' : 'Đã hủy',
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Thông tin (Có thể nối với order_items để hiển thị chi tiết sản phẩm)
              Text('Ngày đặt: ${DateTime.fromMillisecondsSinceEpoch(order['created_at']).toString().substring(0, 16)}', style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Text('Phương thức: ${order['payment_method']}', style: const TextStyle(color: AppColors.textSecondary)),
              const Divider(height: 24),

              // Footer & Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Thành tiền:', style: TextStyle(color: AppColors.textSecondary)),
                  Text('${order['total']}đ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    // Áp dụng ID-Only Rule: Chuyển sang màn chi tiết bằng ID [2]
                    Navigator.pushNamed(context, '/order-detail', arguments: order['id']);
                  },
                  child: const Text('XEM CHI TIẾT'),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}