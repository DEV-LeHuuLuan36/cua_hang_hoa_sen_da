import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/theme_helper.dart';
import '../../../models/common/address.dart';
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
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.6,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Chọn $title',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Divider(height: 1, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (ctx, index) {
                    final itemName = items[index]['name'];
                    return ListTile(
                      title: Text(
                        itemName,
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onTap: () {
                        onSelected(items[index]);
                        Navigator.pop(ctx);
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

  void _openMapPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );
    
    if (result != null && result is String && mounted) {
      setState(() {
        _addressLineController.text = result;
      });
    }
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'Thêm địa chỉ mới',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSection(
              context: context,
              title: 'Liên hệ',
              child: Column(
                children: [
                  TextField(
                    controller: _fullNameController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Họ và tên',
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                      border: InputBorder.none,
                    ),
                  ),
                  Divider(height: 1, color: colorScheme.outlineVariant),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Số điện thoại',
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildSection(
              context: context,
              title: 'Địa chỉ nhận hàng',
              child: _isLoadingLocation
                  ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
                  : Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _selectedProvince ?? 'Tỉnh/Thành phố',
                      style: TextStyle(
                        color: _selectedProvince == null ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                    trailing: Icon(Icons.keyboard_arrow_right, color: colorScheme.onSurfaceVariant),
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
                  Divider(height: 1, color: colorScheme.outlineVariant),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _selectedDistrict ?? 'Quận/Huyện',
                      style: TextStyle(
                        color: _selectedDistrict == null ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                    trailing: Icon(Icons.keyboard_arrow_right, color: colorScheme.onSurfaceVariant),
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
                  Divider(height: 1, color: colorScheme.outlineVariant),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _selectedWard ?? 'Phường/Xã',
                      style: TextStyle(
                        color: _selectedWard == null ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                    trailing: Icon(Icons.keyboard_arrow_right, color: colorScheme.onSurfaceVariant),
                    onTap: () {
                      if (_wards.isEmpty) return;
                      _showLocationBottomSheet('Phường/Xã', _wards, (selected) {
                        setState(() => _selectedWard = selected['name']);
                      });
                    },
                  ),
                  Divider(height: 1, color: colorScheme.outlineVariant),
                  TextField(
                    controller: _addressLineController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Tên đường, Tòa nhà, Số nhà...',
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openMapPicker,
                      icon: Icon(Icons.map, color: AppColors.primary),
                      label: Text('Chọn trên bản đồ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildSection(
              context: context,
              title: 'Cài đặt',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Loại địa chỉ',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Nhà riêng'),
                        selected: _selectedType == AddressType.HOME,
                        selectedColor: AppColors.primaryLight,
                        onSelected: (val) { if (val) setState(() => _selectedType = AddressType.HOME); },
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('Cơ quan'),
                        selected: _selectedType == AddressType.OFFICE,
                        selectedColor: AppColors.primaryLight,
                        onSelected: (val) { if (val) setState(() => _selectedType = AddressType.OFFICE); },
                      ),
                    ],
                  ),
                  Divider(height: 24, color: colorScheme.outlineVariant),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đặt làm mặc định',
                        style: TextStyle(fontSize: 15, color: colorScheme.onSurface),
                      ),
                      Switch(
                        value: _isDefault,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _isDefault = v),
                      ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final userId = context.read<AuthProvider>().currentUser?.id;
              if (userId == null) return;

              if (_fullNameController.text.isEmpty || _phoneController.text.isEmpty || _addressLineController.text.isEmpty ||
                  _selectedProvince == null || _selectedDistrict == null || _selectedWard == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Vui lòng nhập đủ thông tin!', style: TextStyle(color: colorScheme.onPrimary)), backgroundColor: AppColors.error)
                );
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

              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lưu thành công!', style: TextStyle(color: colorScheme.onPrimary)), backgroundColor: AppColors.success)
                  );
                  final newAddress = Address(
                    id: 'addr_${DateTime.now().millisecondsSinceEpoch}',
                    userId: userId,
                    fullName: _fullNameController.text.trim(),
                    phone: _phoneController.text.trim(),
                    city: _selectedProvince ?? '',
                    district: _selectedDistrict ?? '',
                    ward: _selectedWard ?? '',
                    addressLine: _addressLineController.text.trim(),
                    addressType: _selectedType,
                    isDefault: _isDefault,
                    createdAt: DateTime.now().millisecondsSinceEpoch,
                    updatedAt: DateTime.now().millisecondsSinceEpoch,
                  );
                  Navigator.pop(context, newAddress);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi hệ thống!', style: TextStyle(color: colorScheme.onPrimary)), backgroundColor: AppColors.error)
                  );
                }
              }
            },
            child: const Text('HOÀN THÀNH', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required BuildContext context, required String title, required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chọn vị trí',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        backgroundColor: colorScheme.surface,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 16.0),
                  markers: _markers,
                  onTap: _onTapMap,
                  myLocationEnabled: _hasLocationPermission,
                  myLocationButtonEnabled: _hasLocationPermission,
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: colorScheme.surface,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vị trí đã ghim:',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentAddressName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              if (_currentAddressName == 'Đang chọn vị trí...' || _currentAddressName.contains('Không lấy được')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Vui lòng chạm vào bản đồ để chọn 1 vị trí!', style: TextStyle(color: colorScheme.onPrimary)))
                                );
                                return;
                              }
                              Navigator.pop(context, _currentAddressName);
                            },
                            child: const Text('XÁC NHẬN VỊ TRÍ NÀY', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
