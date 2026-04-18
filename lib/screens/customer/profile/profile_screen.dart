import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/constants/route_names.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
            onPressed: () {
              // Cài đặt tài khoản
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header: Avatar & Thông tin (Dữ liệu tĩnh)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nguyễn Văn A', // Mock data
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Thành viên Vàng (Gold)', // Mock data
                          style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Thống kê đơn hàng nhanh
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatusIcon(Icons.inventory_2_outlined, 'Chờ xác nhận', 2),
                    _buildStatusIcon(Icons.local_shipping_outlined, 'Đang giao', 1),
                    _buildStatusIcon(Icons.check_circle_outline, 'Hoàn thành', 0),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 3. Danh sách Menu chức năng
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildMenuItem(context, Icons.receipt_long, 'Đơn hàng của tôi', RouteNames.orderList),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(context, Icons.location_on_outlined, 'Sổ địa chỉ', RouteNames.addressBook), // Dẫn sang trang Sổ địa chỉ
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(context, Icons.favorite_border, 'Sản phẩm yêu thích', ''),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(context, Icons.star_border, 'Đánh giá của tôi', ''),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(context, Icons.confirmation_number_outlined, 'Voucher của tôi', ''),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nút Đăng xuất
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // Logic đăng xuất (Tạm thời chỉ quay về màn hình Login)
                    Navigator.pushReplacementNamed(context, RouteNames.login);
                  },
                  child: const Text('ĐĂNG XUẤT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(IconData icon, String label, int count) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            if (count > 0)
              Positioned(
                right: -5,
                top: -5,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                  child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              )
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {
        if (route.isNotEmpty) {
          // 3. Danh sách Menu chức năng
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildMenuItem(context, Icons.receipt_long, 'Đơn hàng của tôi', RouteNames.orderList),
                const Divider(height: 1, indent: 56),
                _buildMenuItem(context, Icons.location_on_outlined, 'Sổ địa chỉ', RouteNames.addressBook),
                const Divider(height: 1, indent: 56),
                _buildMenuItem(context, Icons.favorite_border, 'Sản phẩm yêu thích', '/wishlist'), // Nối màn Yêu thích
                const Divider(height: 1, indent: 56),
                _buildMenuItem(context, Icons.confirmation_number_outlined, 'Voucher của tôi', '/my-vouchers'), // Nối màn Voucher
                const Divider(height: 1, indent: 56),
                _buildMenuItem(context, Icons.history, 'Đã xem gần đây', '/recently-viewed'),
                const Divider(height: 1, indent: 56),
                _buildMenuItem(context, Icons.star_border, 'Đánh giá của tôi', ''),

              ],
            ),
          );
        }
      },
    );
  }
}