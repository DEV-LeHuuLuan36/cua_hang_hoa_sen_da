import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/common/address.dart';
import '../../../utils/constants/route_names.dart';

class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({Key? key}) : super(key: key);

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  @override
  void initState() {
    super.initState();
    // Tự động tải danh sách địa chỉ khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<UserProvider>().loadUserAddresses(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final addresses = userProvider.addresses;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sổ địa chỉ', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: userProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : addresses.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: addresses.length,
        itemBuilder: (context, index) {
          final address = addresses[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () {
                // KHI BẤM VÀO: Trả địa chỉ này về cho màn hình Checkout
                Navigator.pop(context, address);
              },
              child: _buildAddressCard(address),
            ),
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
              // Mở màn hình thêm địa chỉ mới (Google Maps)
              Navigator.pushNamed(context, RouteNames.addressBook + '/add');
              // Lưu ý: Route này tùy bạn đặt trong app_routes.dart nhé
            },
            child: const Text('+ THÊM ĐỊA CHỈ MỚI',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('Bạn chưa có địa chỉ nào', style: TextStyle(color: Colors.grey, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Address address) {
    return Container(
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
            children: [
              Text(address.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text('(${address.phone})', style: const TextStyle(color: AppColors.textSecondary)),
              const Spacer(),
              if (address.isDefault)
                const Text('[Mặc định]', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4)),
            child: Text(address.addressType.name == 'HOME' ? 'Nhà riêng' : 'Văn phòng',
                style: const TextStyle(color: AppColors.primaryDark, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Text(
            '${address.addressLine}, ${address.ward}, ${address.district}, ${address.city}',
            style: const TextStyle(color: AppColors.textPrimary, height: 1.5),
          ),
        ],
      ),
    );
  }
}