import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/theme_helper.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/auth_provider.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({Key? key}) : super(key: key);

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<OrderProvider>().loadMyOrders(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: ThemeHelper.background(context),
        appBar: AppBar(
          title: Text(
            'Đơn hàng của tôi',
            style: TextStyle(color: ThemeHelper.textPrimary(context)),
          ),
          backgroundColor: ThemeHelper.surface(context),
          elevation: 0,
          iconTheme: IconThemeData(color: ThemeHelper.textPrimary(context)),
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: isDark ? AppColors.darkTextSecondary : Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: const [
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
              return Center(child: CircularProgressIndicator(color: isDark ? AppColors.primary : AppColors.primary));
            }

            final myOrders = orderProvider.myOrders;

            return TabBarView(
              children: [
                _buildOrderList(myOrders, 'PENDING', AppColors.warning, isDark),
                _buildOrderList(myOrders, 'SHIPPING', Colors.blue, isDark),
                _buildOrderList(myOrders, 'DELIVERED', AppColors.success, isDark),
                _buildOrderList(myOrders, 'CANCELLED', AppColors.error, isDark),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders, String statusKey, Color statusColor, bool isDark) {
    final filteredOrders = orders.where((o) => o['order_status'] == statusKey).toList();

    if (filteredOrders.isEmpty) {
      return Center(
        child: Text(
          'Không có đơn hàng nào ở trạng thái này.',
          style: TextStyle(color: ThemeHelper.textSecondary(context)),
        ),
      );
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
            color: ThemeHelper.surface(context),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.black).withValues(alpha: 0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mã ĐH: #${order['order_number']}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: ThemeHelper.textPrimary(context)),
                  ),
                  Text(
                    statusKey == 'PENDING' ? 'Chờ xác nhận' :
                    statusKey == 'SHIPPING' ? 'Đang giao' :
                    statusKey == 'DELIVERED' ? 'Hoàn thành' : 'Đã hủy',
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Divider(height: 24, color: ThemeHelper.divider(context)),
              Text(
                'Ngày đặt: ${DateTime.fromMillisecondsSinceEpoch(order['created_at']).toString().substring(0, 16)}',
                style: TextStyle(color: ThemeHelper.textSecondary(context)),
              ),
              const SizedBox(height: 8),
              Text(
                'Phương thức: ${order['payment_method']}',
                style: TextStyle(color: ThemeHelper.textSecondary(context)),
              ),
              Divider(height: 24, color: ThemeHelper.divider(context)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Thành tiền:', style: TextStyle(color: ThemeHelper.textSecondary(context))),
                  Text(
                    '${order['total']}đ',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
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
