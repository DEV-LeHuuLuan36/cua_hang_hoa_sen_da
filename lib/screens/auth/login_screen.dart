import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/constants/route_names.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../models/enums/user_role.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    // 1. Lấy AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 2. Gọi logic đăng nhập
    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    // 3. Xử lý kết quả
    if (success && mounted) {
      final user = authProvider.currentUser;
      // Dựa vào role để chuyển trang tương ứng (Admin Dashboard hoặc Customer Home)
      if (user?.role == UserRole.ADMIN.name || user?.username.toLowerCase() == 'admin') {
        Navigator.pushReplacementNamed(context, RouteNames.adminDashboard);
      } else {
        Navigator.pushReplacementNamed(context, RouteNames.home);
      }
    } else if (mounted) {
      // Hiển thị thông báo lỗi nếu sai tài khoản
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Đăng nhập thất bại'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe trạng thái loading từ AuthProvider
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Cây Sen Đá (Icon)
              const Icon(Icons.eco, size: 100, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'Hoa Sen Đá',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Đăng nhập để tiếp tục',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),

              // Form nhập liệu
              CustomTextField(
                controller: _usernameController,
                label: 'Tên đăng nhập',
                hint: 'Nhập tên đăng nhập',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                label: 'Mật khẩu',
                hint: 'Nhập mật khẩu',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 24),

              // Nút Đăng Nhập gọi hàm _handleLogin
              CustomButton(
                text: 'ĐĂNG NHẬP',
                isLoading: isLoading,
                onPressed: _handleLogin,
              ),
              const SizedBox(height: 16),

              // Chuyển sang màn hình Đăng ký
              TextButton(
                onPressed: () {
                  // Sẽ mở khóa khi có màn hình Đăng ký
                  Navigator.pushNamed(context, RouteNames.register);
                },
                child: const Text(
                  'Chưa có tài khoản? Đăng ký ngay',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}