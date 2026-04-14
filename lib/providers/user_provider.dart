import 'package:flutter/material.dart';
import '../database/repositories/user_repository.dart';
import '../models/common/address.dart';
import '../models/enums/address_type.dart'; // ĐÃ THÊM IMPORT ENUM ADDRESS TYPE

class UserProvider with ChangeNotifier {
  final UserRepository userRepository;

  UserProvider({required this.userRepository});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Address> _addresses = [];
  List<Address> get addresses => _addresses;

  // 1. Tải danh sách địa chỉ
  Future<void> loadUserAddresses(String userId) async {
    _isLoading = true;
    notifyListeners();

    _addresses = await userRepository.getUserAddresses(userId);

    _isLoading = false;
    notifyListeners();
  }

  // 2. Thêm địa chỉ mới
  Future<bool> addAddress(String userId, Map<String, dynamic> addressData) async {
    _isLoading = true;
    notifyListeners();

    final newAddress = Address(
      id: 'addr_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      fullName: addressData['full_name'],
      phone: addressData['phone'],
      city: addressData['city'],
      district: addressData['district'],
      ward: addressData['ward'],
      addressLine: addressData['address_line'],
      // ĐÃ SỬA LỖI 1: Dùng Enum thay vì chuỗi 'HOME'
      addressType: AddressType.HOME, // (Hoặc AddressType.HOME tùy cách bạn viết hoa/thường trong file enum)
      // ĐÃ SỬA LỖI 2: Dùng trực tiếp giá trị bool thay vì 0 và 1
      isDefault: _addresses.isEmpty,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    final success = await userRepository.addAddress(newAddress);
    if (success) {
      await loadUserAddresses(userId);
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }
}