import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

// Imports cho Map và Location
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../providers/user_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../models/enums/address_type.dart';

class AddEditAddressScreen extends StatefulWidget {
  final String? addressId;

  const AddEditAddressScreen({Key? key, this.addressId}) : super(key: key);

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLineController = TextEditingController();

  AddressType _selectedType = AddressType.HOME;
  bool _isDefault = false;

  List<dynamic> _provinces = [];
  List<dynamic> _districts = [];
  List<dynamic> _wards = [];
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedWard;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _fetchLocationData();
  }

  Future<void> _fetchLocationData() async {
    try {
      final response = await http.get(Uri.parse('https://provinces.open-api.vn/api/?depth=3'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            _provinces = data;
            _isLoadingLocation = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _showLocationBottomSheet(String title, List<dynamic> items, Function(dynamic) onSelected) {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              Text('Chọn $title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final itemName = items[index]['name'];
                    return ListTile(
                      title: Text(itemName, style: const TextStyle(fontSize: 15)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      onTap: () {
                        onSelected(items[index]);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Thêm địa chỉ mới', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. LIÊN HỆ
            _buildSection(
              title: 'Liên hệ',
              child: Column(
                children: [
                  TextField(controller: _fullNameController, decoration: const InputDecoration(hintText: 'Họ và tên', border: InputBorder.none)),
                  const Divider(height: 1),
                  TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'Số điện thoại', border: InputBorder.none)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 2. KHU VỰC ĐỊA CHỈ & BẢN ĐỒ
            _buildSection(
              title: 'Địa chỉ nhận hàng',
              child: _isLoadingLocation
                  ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
                  : Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_selectedProvince ?? 'Tỉnh/Thành phố', style: TextStyle(color: _selectedProvince == null ? Colors.grey.shade600 : Colors.black, fontSize: 16)),
                    trailing: const Icon(Icons.keyboard_arrow_right),
                    onTap: () {
                      _showLocationBottomSheet('Tỉnh/Thành phố', _provinces, (selected) {
                        setState(() {
                          _selectedProvince = selected['name'];
                          _selectedDistrict = null;
                          _selectedWard = null;
                          _districts = selected['districts'] ?? [];
                          _wards = [];
                        });
                      });
                    },
                  ),
                  const Divider(height: 1),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_selectedDistrict ?? 'Quận/Huyện', style: TextStyle(color: _selectedDistrict == null ? Colors.grey.shade600 : Colors.black, fontSize: 16)),
                    trailing: const Icon(Icons.keyboard_arrow_right),
                    onTap: () {
                      if (_districts.isEmpty) return;
                      _showLocationBottomSheet('Quận/Huyện', _districts, (selected) {
                        setState(() {
                          _selectedDistrict = selected['name'];
                          _selectedWard = null;
                          _wards = selected['wards'] ?? [];
                        });
                      });
                    },
                  ),
                  const Divider(height: 1),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_selectedWard ?? 'Phường/Xã', style: TextStyle(color: _selectedWard == null ? Colors.grey.shade600 : Colors.black, fontSize: 16)),
                    trailing: const Icon(Icons.keyboard_arrow_right),
                    onTap: () {
                      if (_wards.isEmpty) return;
                      _showLocationBottomSheet('Phường/Xã', _wards, (selected) {
                        setState(() => _selectedWard = selected['name']);
                      });
                    },
                  ),
                  const Divider(height: 1),

                  // NÚT CHUYỂN SANG MÀN HÌNH BẢN ĐỒ RIÊNG BIỆT (CHỐNG CRASH)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.map, color: Colors.blue),
                    title: const Text('Ghim vị trí trên bản đồ', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
                    onTap: () async {
                      // Chuyển sang màn hình MapPickerScreen và chờ kết quả trả về
                      final selectedAddress = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MapPickerScreen()),
                      );

                      // Nếu chọn được tên đường, tự động điền vào ô
                      if (selectedAddress != null && selectedAddress is String) {
                        setState(() {
                          _addressLineController.text = selectedAddress;
                        });
                      }
                    },
                  ),

                  TextField(
                    controller: _addressLineController,
                    decoration: const InputDecoration(hintText: 'Tên đường, Tòa nhà, Số nhà...', border: InputBorder.none),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 3. CÀI ĐẶT
            _buildSection(
              title: 'Cài đặt',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Loại địa chỉ', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Nhà riêng'),
                        selected: _selectedType == AddressType.HOME,
                        onSelected: (val) { if (val) setState(() => _selectedType = AddressType.HOME); },
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('Cơ quan'),
                        selected: _selectedType == AddressType.OFFICE,
                        onSelected: (val) { if (val) setState(() => _selectedType = AddressType.OFFICE); },
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Đặt làm mặc định', style: TextStyle(fontSize: 15)),
                      Switch(value: _isDefault, activeColor: AppColors.primary, onChanged: (v) => setState(() => _isDefault = v)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: () async {
              final userId = context.read<AuthProvider>().currentUser?.id;
              if (userId == null) return;

              if (_fullNameController.text.isEmpty || _phoneController.text.isEmpty || _addressLineController.text.isEmpty ||
                  _selectedProvince == null || _selectedDistrict == null || _selectedWard == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đủ thông tin!')));
                return;
              }

              final addressData = {
                'full_name': _fullNameController.text.trim(),
                'phone': _phoneController.text.trim(),
                'city': _selectedProvince,
                'district': _selectedDistrict,
                'ward': _selectedWard,
                'address_line': _addressLineController.text.trim(),
                'address_type': _selectedType.name,
                'is_default': _isDefault ? 1 : 0,
              };

              final success = await context.read<UserProvider>().addAddress(userId, addressData);

              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu thành công!'), backgroundColor: AppColors.success));
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi hệ thống!'), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('HOÀN THÀNH', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// =========================================================================
// MÀN HÌNH BẢN ĐỒ RIÊNG BIỆT - ĐẢM BẢO KHÔNG BAO GIỜ CRASH VÀ XUNG ĐỘT SCROLL
// =========================================================================
class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({Key? key}) : super(key: key);

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? mapController;
  final LatLng _initialPosition = const LatLng(10.776889, 106.700806);
  Set<Marker> _markers = {};
  bool _hasLocationPermission = false;
  String _currentAddressName = 'Đang chọn vị trí...';

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted && mounted) {
      setState(() => _hasLocationPermission = true);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    setState(() {
      _markers.add(Marker(markerId: const MarkerId('selected_location'), position: _initialPosition));
    });
  }

  void _onTapMap(LatLng location) async {
    setState(() {
      _currentAddressName = 'Đang tải tên đường...';
      _markers.clear();
      _markers.add(Marker(markerId: const MarkerId('selected_location'), position: location));
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String newAddress = '';
        if (place.street != null && place.street!.isNotEmpty) newAddress = place.street!;
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          newAddress += newAddress.isEmpty ? place.subLocality! : ', ${place.subLocality}';
        }
        setState(() {
          _currentAddressName = newAddress;
        });
      }
    } catch (e) {
      setState(() {
        _currentAddressName = 'Không lấy được tên đường. Vui lòng chọn lại!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn vị trí', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 16.0),
            markers: _markers,
            onTap: _onTapMap,
            myLocationEnabled: _hasLocationPermission,
            myLocationButtonEnabled: _hasLocationPermission,
          ),

          // Thanh hiển thị địa chỉ đang chọn
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vị trí đã ghim:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(_currentAddressName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        if (_currentAddressName == 'Đang chọn vị trí...' || _currentAddressName.contains('Không lấy được')) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chạm vào bản đồ để chọn 1 vị trí!')));
                          return;
                        }
                        // Trả tên đường về lại trang Form
                        Navigator.pop(context, _currentAddressName);
                      },
                      child: const Text('XÁC NHẬN VỊ TRÍ NÀY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}