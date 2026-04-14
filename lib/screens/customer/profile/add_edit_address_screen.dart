import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/auth_provider.dart';

class AddEditAddressScreen extends StatefulWidget {
  final String? addressId; // Nhận addressId (null nếu là thêm mới)

  const AddEditAddressScreen({Key? key, this.addressId}) : super(key: key);

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  late GoogleMapController mapController;

  // Tọa độ mặc định (VD: Trung tâm TP.HCM)
  final LatLng _initialPosition = const LatLng(10.776889, 106.700806);
  Set<Marker> _markers = {};

  // Controllers cho các trường trong bảng addresses
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLineController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _wardController = TextEditingController();

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _initialPosition,
          infoWindow: const InfoWindow(title: 'Vị trí giao hàng'),
        ),
      );
    });
  }

  void _onTapMap(LatLng location) {
    setState(() {
      _markers.clear();
      _markers.add(Marker(
        markerId: const MarkerId('selected_location'),
        position: location,
        infoWindow: const InfoWindow(title: 'Vị trí đã chọn'),
      ));
    });
    // Ở đây bạn có thể dùng thêm package 'geocoding' để tự động
    // điền _addressLine, _city... dựa vào tọa độ (location)
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressLineController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.addressId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa địa chỉ' : 'Thêm địa chỉ mới', style: const TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          // 1. Bản đồ Google Maps
          SizedBox(
            height: 250,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 15.0),
              markers: _markers,
              onTap: _onTapMap,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),

          // 2. Form nhập liệu chuẩn Data Schema
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    TextField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(labelText: 'Tên người nhận (full_name)', prefixIcon: Icon(Icons.person)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Số điện thoại (phone)', prefixIcon: Icon(Icons.phone)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'Tỉnh/Thành phố (city)', prefixIcon: Icon(Icons.location_city)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _districtController, decoration: const InputDecoration(labelText: 'Quận/Huyện'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _wardController, decoration: const InputDecoration(labelText: 'Phường/Xã'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressLineController,
                      decoration: const InputDecoration(labelText: 'Số nhà, Tên đường (address_line)', prefixIcon: Icon(Icons.home)),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: ()async {
              // 1. Lấy user hiện tại
              final userId = context.read<AuthProvider>().currentUser?.id;
              if (userId == null) return;

              // 2. Kiểm tra dữ liệu rỗng
              if (_fullNameController.text.isEmpty || _phoneController.text.isEmpty || _addressLineController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đủ thông tin!')));
                return;
              }

              // 3. Đóng gói dữ liệu
              final addressData = {
                'full_name': _fullNameController.text.trim(),
                'phone': _phoneController.text.trim(),
                'city': _cityController.text.trim(),
                'district': _districtController.text.trim(),
                'ward': _wardController.text.trim(),
                'address_line': _addressLineController.text.trim(),
              };

              // 4. Gọi Provider lưu vào SQLite
              final success = await context.read<UserProvider>().addAddress(userId, addressData);

              // 5. Thông báo và thoát
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Lưu địa chỉ thành công!'),
                  backgroundColor: AppColors.success,
                )
                );
                Navigator.pop(context); // Trở về màn Sổ địa chỉ
              }
            },
  child: const Text('LƯU ĐỊA CHỈ', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}