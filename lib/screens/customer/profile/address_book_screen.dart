import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/theme_helper.dart';
import '../../../utils/constants/route_names.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/common/address.dart';
import '../../../widgets/common/shimmer_box.dart';

class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({Key? key}) : super(key: key);

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser != null) {
        context.read<UserProvider>().loadUserAddresses(authProvider.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: ThemeHelper.background(context),
      appBar: AppBar(
        title: Text(
          'Sổ địa chỉ',
          style: TextStyle(color: ThemeHelper.textPrimary(context), fontWeight: FontWeight.bold),
        ),
        backgroundColor: ThemeHelper.surface(context),
        elevation: 0.5,
        iconTheme: IconThemeData(color: ThemeHelper.textPrimary(context)),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: ShimmerListItem(height: 100, borderRadius: 12),
              ),
            );
          }

          if (userProvider.addresses.isEmpty) {
            return Center(
              child: Text(
                'Bạn chưa có địa chỉ nào.',
                style: TextStyle(color: ThemeHelper.textSecondary(context)),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: userProvider.addresses.length,
            itemBuilder: (context, index) {
              final addr = userProvider.addresses[index];
              return _buildAddressCard(context, addr, isDark);
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
              Navigator.pushNamed(context, '${RouteNames.addressBook}/add');
            },
            child: const Text('+ THÊM ĐỊA CHỈ MỚI', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, Address address, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeHelper.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: address.isDefault ? Border.all(color: AppColors.primary, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                address.fullName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ThemeHelper.textPrimary(context),
                ),
              ),
              InkWell(
                onTap: () => Navigator.pushNamed(context, '${RouteNames.addressBook}/edit', arguments: address.id),
                child: Text(
                  'Sửa',
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            address.phone,
            style: TextStyle(color: ThemeHelper.textSecondary(context)),
          ),
          const SizedBox(height: 8),
          Text(
            '${address.addressLine}, ${address.ward}, ${address.district}, ${address.city}',
            style: TextStyle(color: ThemeHelper.textPrimary(context)),
          ),
          if (address.isDefault) ...[
            const SizedBox(height: 8),
            Text(
              '[Mặc định]',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ]
        ],
      ),
    );
  }
}
