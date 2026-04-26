import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/constants/route_names.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user/customer.dart';
import '../../../models/enums/membership_level.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUpdatingAvatar = false;

  Future<void> _pickAvatar() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        setState(() => _isUpdatingAvatar = true);
        
        final authProvider = context.read<AuthProvider>();
        final success = await authProvider.updateAvatar(image.path);
        
        if (mounted) {
          setState(() => _isUpdatingAvatar = false);
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cập nhật ảnh đại diện thành công!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdatingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Lấy thông tin từ AuthProvider
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    // 2. Lấy dữ liệu đơn hàng
    final orderProvider = context.watch<OrderProvider>();
    final myOrders = orderProvider.myOrders;

    int pendingCount = myOrders.where((order) => order['order_status'] == 'PENDING').length;
    int shippingCount = myOrders.where((order) => order['order_status'] == 'SHIPPING').length;
    int completedCount = myOrders.where((order) => order['order_status'] == 'DELIVERED').length;

    // 3. Xử lý logic hiển thị thông tin thực tế
    String displayName = user?.fullName ?? 'Khách hàng';
    String displayLevel = 'Thành viên Đồng';
    Color levelColor = Colors.brown.shade600;

    if (user != null) {
      switch (user.membershipLevel) {
        case MembershipLevel.BRONZE:
          displayLevel = 'Thành viên Đồng';
          levelColor = Colors.brown.shade600;
          break;
        case MembershipLevel.SILVER:
          displayLevel = 'Thành viên Bạc';
          levelColor = Colors.grey.shade600;
          break;
        case MembershipLevel.GOLD:
          displayLevel = 'Thành viên Vàng';
          levelColor = Colors.orange.shade700;
          break;
        case MembershipLevel.PLATINUM:
          displayLevel = 'Thành viên Bạch kim';
          levelColor = Colors.blue.shade800;
          break;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.pushNamed(context, RouteNames.settings);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header: Hiển thị thông tin tên và cấp độ thực tế
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  // Avatar với icon camera
                  GestureDetector(
                    onTap: _isUpdatingAvatar ? null : _pickAvatar,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.primaryLight,
                            backgroundImage: user?.avatar != null && user!.avatar!.isNotEmpty
                                ? FileImage(File(user!.avatar!))
                                : null,
                            child: user?.avatar == null || user!.avatar!.isEmpty
                                ? const Icon(Icons.person, size: 40, color: Colors.white)
                                : null,
                          ),
                        ),
                        if (_isUpdatingAvatar)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayLevel,
                          style: TextStyle(color: levelColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Thống kê đơn hàng nhanh
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
                    _buildStatusIcon(Icons.inventory_2_outlined, 'Chờ xác nhận', pendingCount),
                    _buildStatusIcon(Icons.local_shipping_outlined, 'Đang giao', shippingCount),
                    _buildStatusIcon(Icons.check_circle_outline, 'Hoàn thành', completedCount),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Danh sách Menu chức năng
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildMenuItem(context, Icons.receipt_long, 'Đơn hàng của tôi', RouteNames.orderList),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(context, Icons.location_on_outlined, 'Sổ địa chỉ', RouteNames.addressBook),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(context, Icons.favorite_border, 'Sản phẩm yêu thích', RouteNames.wishlist),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(context, Icons.confirmation_number_outlined, 'Voucher của tôi', RouteNames.myVouchers),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(context, Icons.history, 'Đã xem gần đây', RouteNames.recentlyViewed),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(context, Icons.star_border, 'Đánh giá của tôi', RouteNames.myReviews),
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
                    context.read<AuthProvider>().logout();
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
          Navigator.pushNamed(context, route);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tính năng đang phát triển'), duration: Duration(seconds: 1)),
          );
        }
      },
    );
  }
}