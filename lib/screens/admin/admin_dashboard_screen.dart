import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../database/daos/category_dao.dart';
import '../../database/daos/order_dao.dart';
import '../../database/daos/product_dao.dart';
import '../../database/repositories/order_repository.dart';
import '../../database/repositories/product_repository.dart';
import '../../models/product/succulent.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants/route_names.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/pressable_scale.dart';
import '../../widgets/common/shimmer_box.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final OrderRepository _orderRepository;
  late final ProductRepository _productRepository;

  bool _isLoading = true;
  double _totalRevenue = 0;
  int _newOrders = 0;
  int _lowStockProducts = 0;

  @override
  void initState() {
    super.initState();
    _orderRepository = OrderRepository(orderDao: OrderDao());
    _productRepository = ProductRepository(
      productDao: ProductDao(),
      categoryDao: CategoryDao(),
    );
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final orders = await _orderRepository.getAllOrders();
    final products = await _productRepository.getAllProducts();

    final revenue = orders.fold<double>(
      0,
      (sum, order) => sum + ((order['total'] as num?)?.toDouble() ?? 0),
    );
    final pendingOrders = orders.where((o) => o['order_status'] == 'PENDING').length;
    final lowStock = products.where((Succulent p) => p.stock < 5).length;

    if (!mounted) return;
    setState(() {
      _totalRevenue = revenue;
      _newOrders = pendingOrders;
      _lowStockProducts = lowStock;
      _isLoading = false;
    });
  }

  String _formatMoney(double value) => '${value.toInt()}đ';

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return PressableScale(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pushNamed(context, route);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Quản Trị Cửa Hàng', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primaryDark,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushReplacementNamed(context, RouteNames.login);
            },
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              if (_isLoading)
                GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.65,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    ShimmerBox(width: double.infinity, height: 120, borderRadius: 16),
                    ShimmerBox(width: double.infinity, height: 120, borderRadius: 16),
                    ShimmerBox(width: double.infinity, height: 120, borderRadius: 16),
                  ],
                )
              else
                GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.65,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard(
                      title: 'Tổng doanh thu',
                      value: _formatMoney(_totalRevenue),
                      icon: Icons.paid_rounded,
                      iconColor: AppColors.success,
                    ),
                    _buildStatCard(
                      title: 'Đơn hàng mới',
                      value: _newOrders.toString(),
                      icon: Icons.receipt_long_rounded,
                      iconColor: AppColors.warning,
                    ),
                    _buildStatCard(
                      title: 'Sắp hết hàng',
                      value: _lowStockProducts.toString(),
                      icon: Icons.inventory_2_rounded,
                      iconColor: AppColors.error,
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              _buildFeatureCard(
                context: context,
                title: 'Quản lý sản phẩm',
                icon: Icons.inventory_2_outlined,
                color: Colors.blue,
                route: RouteNames.adminProductList,
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                context: context,
                title: 'Quản lý đơn hàng',
                icon: Icons.receipt_long_outlined,
                color: Colors.orange,
                route: RouteNames.adminOrderList,
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                context: context,
                title: 'Quản lý Voucher',
                icon: Icons.local_offer_outlined,
                color: Colors.pink,
                route: RouteNames.adminVoucher,
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                context: context,
                title: 'Báo cáo cửa hàng',
                icon: Icons.analytics_outlined,
                color: Colors.deepPurple,
                route: RouteNames.adminReport,
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}