import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart'; // Đừng quên cài flutter pub add geocoding
import 'package:permission_handler/permission_handler.dart'; // Thư viện vừa cài
import 'package:provider/provider.dart';

import '../../../providers/user_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_colors.dart';

class AddEditAddressScreen extends StatefulWidget {
  final String? addressId;

  const AddEditAddressScreen({Key? key, this.addressId}) : super(key: key);

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  GoogleMapController? mapController;

  final LatLng _initialPosition = const LatLng(10.776889, 106.700806);
  Set<Marker> _markers = {};
  bool _hasLocationPermission = false; // Trạng thái quyền

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLineController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _wardController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestLocationPermission(); // Gọi hàm xin quyền ngay khi mở màn hình
  }

  // HÀM HIỂN THỊ POPUP XIN QUYỀN
  Future<void> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      setState(() {
        _hasLocationPermission = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần cấp quyền vị trí để sử dụng bản đồ chính xác!')),
      );
    }
  }

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

  // HÀM BẤM VÀO BẢN ĐỒ VÀ DỊCH TỌA ĐỘ
  void _onTapMap(LatLng location) async {
    setState(() {
      _markers.clear();
      _markers.add(Marker(
        markerId: const MarkerId('selected_location'),
        position: location,
        infoWindow: const InfoWindow(title: 'Vị trí đã chọn'),
      ));
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _addressLineController.text = place.street ?? '';
          _wardController.text = place.subLocality ?? '';
          _districtController.text = place.locality ?? place.subAdministrativeArea ?? '';
          _cityController.text = place.administrativeArea ?? '';
        });
      }
    } catch (e) {
      debugPrint("Lỗi giải mã địa chỉ: $e");
    }
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
          // BẢN ĐỒ
          SizedBox(
            height: 250,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 15.0),
              markers: _markers,
              onTap: _onTapMap,
              // Chỉ bật MyLocation nếu đã được cấp quyền, tránh bị đơ bản đồ
              myLocationEnabled: _hasLocationPermission,
              myLocationButtonEnabled: _hasLocationPermission,
            ),
          ),

          // FORM NHẬP LIỆU
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    TextField(controller: _fullNameController, decoration: const InputDecoration(labelText: 'Tên người nhận (full_name)', prefixIcon: Icon(Icons.person))),
                    const SizedBox(height: 12),
                    TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Số điện thoại (phone)', prefixIcon: Icon(Icons.phone))),
                    const SizedBox(height: 12),
                    TextField(controller: _cityController, decoration: const InputDecoration(labelText: 'Tỉnh/Thành phố (city)', prefixIcon: Icon(Icons.location_city))),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _districtController, decoration: const InputDecoration(labelText: 'Quận/Huyện'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _wardController, decoration: const InputDecoration(labelText: 'Phường/Xã'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _addressLineController, decoration: const InputDecoration(labelText: 'Số nhà, Tên đường', prefixIcon: Icon(Icons.home))),
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
            onPressed: () async {
              final userId = context.read<AuthProvider>().currentUser?.id;
              if (userId == null) return;

              if (_fullNameController.text.isEmpty || _phoneController.text.isEmpty || _addressLineController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đủ thông tin!')));
                return;
              }

              final addressData = {
                'full_name': _fullNameController.text.trim(),
                'phone': _phoneController.text.trim(),
                'city': _cityController.text.trim(),
                'district': _districtController.text.trim(),
                'ward': _wardController.text.trim(),
                'address_line': _addressLineController.text.trim(),
              };

              final success = await context.read<UserProvider>().addAddress(userId, addressData);

              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu địa chỉ thành công!'), backgroundColor: AppColors.success));
                Navigator.pop(context);
              }
            },
            child: const Text('LƯU ĐỊA CHỈ', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}