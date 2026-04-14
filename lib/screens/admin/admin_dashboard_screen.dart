import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants/route_names.dart';
import '../../providers/auth_provider.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildAdminCard(
              context,
              title: 'Quản lý Sản phẩm',
              icon: Icons.inventory_2_outlined,
              color: Colors.blue,
              route: RouteNames.adminProductList, // Chuyển sang danh sách SP [1]
            ),
            const SizedBox(height: 16),
            _buildAdminCard(
              context,
              title: 'Quản lý Đơn hàng',
              icon: Icons.receipt_long_outlined,
              color: Colors.orange,
                route: '/admin-order-list',
            ),
            const SizedBox(height: 16),
            _buildAdminCard(
              context,
              title: 'Cài đặt Shop',
              icon: Icons.settings_outlined,
              color: Colors.grey,
              route: '/admin-report',
            ),
            const SizedBox(height: 16),
            _buildAdminCard(
              context,
              title: 'Cài đặt Shop',
              icon: Icons.settings_outlined,
              color: Colors.grey,
              route: '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, {required String title, required IconData icon, required Color color, required String route}) {
    return InkWell(
      onTap: () {
        if (route.isNotEmpty) Navigator.pushNamed(context, route);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}