import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/constants/route_names.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/common/address.dart'; // Đảm bảo import này đúng

class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({Key? key}) : super(key: key);

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  @override
  void initState() {
    super.initState();
    // Gọi tải dữ liệu ngay khi vào trang
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser != null) {
        context.read<UserProvider>().loadUserAddresses(authProvider.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sổ địa chỉ', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userProvider.addresses.isEmpty) {
            return const Center(child: Text('Bạn chưa có địa chỉ nào.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: userProvider.addresses.length,
            itemBuilder: (context, index) {
              final addr = userProvider.addresses[index];
              return _buildAddressCard(context, addr);
            },
          );
        },
      ),
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
              // Nút này giờ sẽ hoạt động vì Route đã được định nghĩa trong app_routes.dart
              Navigator.pushNamed(context, '${RouteNames.addressBook}/add');
            },
            child: const Text('+ THÊM ĐỊA CHỈ MỚI', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, Address address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: address.isDefault ? Border.all(color: AppColors.primary, width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(address.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () => Navigator.pushNamed(context, '${RouteNames.addressBook}/edit', arguments: address.id),
                child: const Text('Sửa', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(address.phone, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Text('${address.addressLine}, ${address.ward}, ${address.district}, ${address.city}'),
          if (address.isDefault) ...[
            const SizedBox(height: 8),
            const Text('[Mặc định]', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12)),
          ]
        ],
      ),
    );
  }
}