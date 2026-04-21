import 'package:flutter/material.dart';
import '../database/repositories/user_repository.dart';
import '../models/common/address.dart';
import '../models/enums/address_type.dart';

class UserProvider with ChangeNotifier {
  final UserRepository userRepository;

  UserProvider({required this.userRepository});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Address> _addresses = [];
  List<Address> get addresses => _addresses;

  // Hàm tải địa chỉ - Screen sẽ gọi hàm này
  Future<void> loadUserAddresses(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _addresses = await userRepository.getUserAddresses(userId);
    } catch (e) {
      debugPrint("Lỗi loadUserAddresses: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // Hàm thêm địa chỉ
  Future<bool> addAddress(String userId, Map<String, dynamic> addressData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newAddress = Address(
        id: 'addr_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        fullName: addressData['full_name'] ?? '',
        phone: addressData['phone'] ?? '',
        city: addressData['city'] ?? '',
        district: addressData['district'] ?? '',
        ward: addressData['ward'] ?? '',
        addressLine: addressData['address_line'] ?? '',
        addressType: AddressType.fromString(addressData['address_type'] ?? 'HOME'),
        isDefault: addressData['is_default'] == 1,
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
    } catch (e) {
      debugPrint("Lỗi addAddress: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}