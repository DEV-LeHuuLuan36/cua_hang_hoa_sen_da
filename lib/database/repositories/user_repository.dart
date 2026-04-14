import '../../models/user/user.dart';
import '../../models/common/address.dart';
import '../daos/user_dao.dart';
import '../daos/address_dao.dart';

class UserRepository {
  final UserDao _userDao;
  final AddressDao _addressDao;

  // Tiêm phụ thuộc (Dependency Injection) qua constructor
  UserRepository({
    required UserDao userDao,
    required AddressDao addressDao,
  })  : _userDao = userDao,
        _addressDao = addressDao;

  // --- SỔ ĐỊA CHỈ ---
  Future<List<Address>> getUserAddresses(String userId) async {
    try {
      return await _addressDao.getAddressesByUser(userId);
    } catch (e) {
      print("Lỗi lấy sổ địa chỉ: $e");
      return [];
    }
  }

  Future<bool> addAddress(Address address) async {
    try {
      final result = await _addressDao.insertAddress(address);
      return result > 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateAddress(Address address) async {
    try {
      final result = await _addressDao.updateAddress(address);
      return result > 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAddress(String addressId) async {
    try {
      final result = await _addressDao.deleteAddress(addressId);
      return result > 0;
    } catch (e) {
      return false;
    }
  }

  // --- HỒ SƠ CÁ NHÂN ---
  Future<User?> getUserProfile(String userId) async {
    try {
      return await _userDao.getUserById(userId);
    } catch (e) {
      return null;
    }
  }
}