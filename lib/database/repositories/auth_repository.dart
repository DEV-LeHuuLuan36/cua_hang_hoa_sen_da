import '../../models/user/user.dart';
import '../../models/user/customer.dart';
import '../daos/user_dao.dart';

class AuthRepository {
  final UserDao _userDao;

  // Nhận UserDao qua constructor để đảm bảo tính Decoupling (Giảm phụ thuộc)
  AuthRepository({required UserDao userDao}) : _userDao = userDao;

  // Nghiệp vụ đăng nhập
  Future<User?> login(String username, String password) async {
    try {
      return await _userDao.login(username, password);
    } catch (e) {
      print("Lỗi đăng nhập: $e");
      return null;
    }
  }

  // Nghiệp vụ đăng ký tài khoản (Mặc định là Customer)
  Future<bool> register(Customer newCustomer) async {
    try {
      final id = await _userDao.insertUser(newCustomer);
      return id > 0; // Trả về true nếu insert thành công
    } catch (e) {
      print("Lỗi đăng ký: $e");
      return false;
    }
  }

  // Lấy thông tin user
  Future<User?> getUserProfile(String userId) async {
    try {
      return await _userDao.getUserById(userId);
    } catch (e) {
      print("Lỗi lấy thông tin User: $e");
      return null;
    }
  }

  // Cập nhật thông tin user
  Future<bool> updateUser(User user) async {
    try {
      final result = await _userDao.updateUser(user);
      return result > 0;
    } catch (e) {
      print("Lỗi cập nhật User: $e");
      return false;
    }
  }
}