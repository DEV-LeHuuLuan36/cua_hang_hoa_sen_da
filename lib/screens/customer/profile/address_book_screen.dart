import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class AddressBookScreen extends StatelessWidget {
  const AddressBookScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sổ địa chỉ', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Thẻ địa chỉ 1 (Mặc định)
          _buildAddressCard(
            name: 'Nguyễn Văn A',
            phone: '0901234567',
            address: 'Số 123 Đường ABC, Phường XYZ, Quận 1, TP. HCM',
            type: 'Nhà riêng',
            isDefault: true,
          ),
          const SizedBox(height: 16),
          // Thẻ địa chỉ 2
          _buildAddressCard(
            name: 'Nguyễn Văn A',
            phone: '0987654321',
            address: 'Tòa nhà văn phòng DEF, Phường MNP, Quận 3, TP. HCM',
            type: 'Cơ quan',
            isDefault: false,
          ),
        ],
      ),
      // Nút Thêm địa chỉ mới
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              // Mở form Thêm địa chỉ
            },
            child: const Text('+ THÊM ĐỊA CHỈ MỚI', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard({required String name, required String phone, required String address, required String type, required bool isDefault}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDefault ? Border.all(color: AppColors.primary, width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text('($phone)', style: const TextStyle(color: AppColors.textSecondary)),
              const Spacer(),
              // Nút chỉnh sửa
              const Text('Sửa', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primaryLight.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                child: Text(type, style: const TextStyle(color: AppColors.primaryDark, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              if (isDefault)
                const Text('[Mặc định]', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(address, style: const TextStyle(color: AppColors.textPrimary, height: 1.5)),
        ],
      ),
    );
  }
}