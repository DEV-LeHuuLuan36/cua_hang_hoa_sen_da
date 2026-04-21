import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isNotificationEnabled = true;

  @override
  Widget build(BuildContext context) {
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
              onTap: () {
                // Điều hướng sang trang sửa thông tin (Lê Hữu Luân)
              },
            ),
            _buildSettingItem(
              icon: Icons.shield_outlined,
              title: 'Đổi mật khẩu',
              onTap: () {},
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
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.policy_outlined,
              title: 'Chính sách bảo mật',
              onTap: () {},
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