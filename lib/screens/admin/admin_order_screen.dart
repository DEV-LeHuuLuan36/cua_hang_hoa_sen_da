import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/theme_helper.dart';
import '../../widgets/common/pressable_scale.dart';
import '../../widgets/common/shimmer_box.dart';

class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({Key? key}) : super(key: key);

  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadAllOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: ThemeHelper.background(context),
      appBar: AppBar(
        title: const Text('Quản lý Đơn hàng', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryDark,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoading) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: ShimmerBox(width: double.infinity, height: 120, borderRadius: 12),
              ),
            );
          }

          final orders = [...orderProvider.allOrders]
            ..sort(
              (a, b) => ((b['created_at'] as num?)?.toInt() ?? 0)
                  .compareTo((a['created_at'] as num?)?.toInt() ?? 0),
            );

          if (orders.isEmpty) {
            return Center(
              child: Text(
                'Không có đơn hàng nào.',
                style: TextStyle(color: ThemeHelper.textSecondary(context)),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderCard(order, context, isDark);
            },
          );
        },
      ),
    );
  }

  String _nextStatus(String currentStatus) {
    if (currentStatus == 'PENDING') return 'SHIPPING';
    if (currentStatus == 'SHIPPING') return 'DELIVERED';
    return 'DELIVERED';
  }

  String _statusLabel(String status) {
    if (status == 'PENDING') return 'Chờ xử lý';
    if (status == 'SHIPPING') return 'Đang giao';
    if (status == 'DELIVERED') return 'Đã giao';
    return status;
  }

  Color _statusColor(String status) {
    if (status == 'PENDING') return AppColors.warning;
    if (status == 'SHIPPING') return Colors.blue;
    if (status == 'DELIVERED') return AppColors.success;
    return AppColors.textSecondary;
  }

  Future<void> _updateStatus(BuildContext context, String orderId, String currentStatus) async {
    if (currentStatus == 'DELIVERED') return;
    HapticFeedback.lightImpact();
    final success = await context.read<OrderProvider>().updateOrderStatus(orderId, _nextStatus(currentStatus));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Cập nhật trạng thái thành công!' : 'Cập nhật trạng thái thất bại!'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, BuildContext context, bool isDark) {
    final orderId = order['id']?.toString() ?? '';
    final currentStatus = order['order_status']?.toString() ?? 'PENDING';
    final statusColor = _statusColor(currentStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeHelper.surface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.textPrimary).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ĐH: #${order['order_number']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: ThemeHelper.textPrimary(context),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabel(currentStatus),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ngày đặt: ${DateTime.fromMillisecondsSinceEpoch(order['created_at']).toString().substring(0, 16)}',
            style: TextStyle(color: ThemeHelper.textSecondary(context)),
          ),
          const SizedBox(height: 4),
          Text(
            'Tổng tiền: ${(order['total'] as num?)?.toInt() ?? 0}đ',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (currentStatus != 'DELIVERED')
            PressableScale(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _updateStatus(context, orderId, currentStatus),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    currentStatus == 'PENDING'
                        ? 'CHUYỂN SANG ĐANG GIAO'
                        : 'ĐÁNH DẤU ĐÃ GIAO',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
