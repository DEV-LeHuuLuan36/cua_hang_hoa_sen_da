import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/constants/route_names.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isNotificationEnabled = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Cài đặt tài khoản',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Tài khoản'),
            _buildSettingItem(
              icon: Icons.person_outline,
              title: 'Chỉnh sửa hồ sơ',
              onTap: () => _showEditProfileDialog(context, user?.fullName ?? '', user?.phone ?? ''),
            ),
            _buildSettingItem(
              icon: Icons.shield_outlined,
              title: 'Đổi mật khẩu',
              onTap: () => _showChangePasswordDialog(context),
            ),

            _buildSectionTitle('Thông báo'),
            Container(
              color: Colors.white,
              child: ListTile(
                leading: const Icon(Icons.notifications_none, color: AppColors.primary),
                title: const Text('Thông báo đẩy', style: TextStyle(fontSize: 16)),
                trailing: Switch(
                  value: _isNotificationEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      _isNotificationEnabled = value;
                    });
                  },
                ),
              ),
            ),

            _buildSectionTitle('Hỗ trợ & Pháp lý'),
            _buildSettingItem(
              icon: Icons.help_outline,
              title: 'Trung tâm trợ giúp',
              onTap: () => Navigator.pushNamed(context, RouteNames.support),
            ),
            _buildSettingItem(
              icon: Icons.policy_outlined,
              title: 'Chính sách bảo mật',
              onTap: () => Navigator.pushNamed(context, RouteNames.legal),
            ),
            _buildSettingItem(
              icon: Icons.info_outline,
              title: 'Về ứng dụng',
              trailing: const Text('v1.0.0', style: TextStyle(color: Colors.grey)),
              onTap: () {},
            ),

            const SizedBox(height: 30),
            _buildDeleteAccountButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditProfileDialog(BuildContext context, String currentName, String currentPhone) async {
    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone);
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Chỉnh sửa hồ sơ'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập họ tên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập số điện thoại';
                    }
                    if (value.length < 10) {
                      return 'Số điện thoại không hợp lệ';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('HỦY'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setDialogState(() => isLoading = true);
                        
                        final authProvider = context.read<AuthProvider>();
                        final success = await authProvider.updateProfile(
                          nameController.text.trim(),
                          phoneController.text.trim(),
                        );
                        
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Cập nhật thành công!' : 'Cập nhật thất bại'),
                              backgroundColor: success ? AppColors.success : AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('LƯU', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    phoneController.dispose();
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    bool _obscureOld = true;
    bool _obscureNew = true;
    bool _obscureConfirm = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Đổi mật khẩu'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: oldPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu cũ',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDialogState(() => _obscureOld = !_obscureOld),
                    ),
                  ),
                  obscureText: _obscureOld,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu cũ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDialogState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  obscureText: _obscureNew,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu mới';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu mới',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDialogState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  obscureText: _obscureConfirm,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng xác nhận mật khẩu';
                    }
                    if (value != newPasswordController.text) {
                      return 'Mật khẩu xác nhận không khớp';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('HỦY'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setDialogState(() => isLoading = true);
                        
                        final authProvider = context.read<AuthProvider>();
                        
                        // Kiểm tra mật khẩu cũ
                        final isValid = await authProvider.verifyOldPassword(oldPasswordController.text);
                        
                        if (!isValid) {
                          if (mounted) {
                            setDialogState(() => isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Mật khẩu cũ không đúng!'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                          return;
                        }
                        
                        // Đổi mật khẩu
                        final success = await authProvider.changePassword(newPasswordController.text);
                        
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Đổi mật khẩu thành công!' : 'Đổi mật khẩu thất bại'),
                              backgroundColor: success ? AppColors.success : AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('ĐỔI MẬT KHẨU', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: AppColors.primary),
            title: Text(title, style: const TextStyle(fontSize: 16)),
            trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: onTap,
          ),
          const Divider(height: 1, indent: 56),
        ],
      ),
    );
  }

  Widget _buildDeleteAccountButton() {
    return Center(
      child: TextButton(
        onPressed: () {
          // Logic xóa tài khoản
        },
        child: const Text(
          'Xóa tài khoản',
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}