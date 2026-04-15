import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../models/user/user.dart';
import '../../models/user/customer.dart';
import '../daos/user_dao.dart';

class AuthRepository {
  final UserDao _userDao;

  // Nhận UserDao qua constructor để đảm bảo tính Decoupling (Giảm phụ thuộc)
  AuthRepository({required UserDao userDao}) : _userDao = userDao;
  // Hàm nội bộ để băm mật khẩu
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // Nghiệp vụ đăng nhập
  Future<User?> login(String username, String password) async {
    try {
      // Băm mật khẩu người dùng nhập vào trước khi so khớp với DB
      final hashedPassword = _hashPassword(password);
      return await _userDao.login(username, hashedPassword);
    } catch (e) {
      return null;
    }
  }

  Future<String?> register(Customer customer) async {
    try {
      // 1. Kiểm tra trùng lặp (nếu UserDao có hỗ trợ)
      // 2. Mã hóa mật khẩu trước khi lưu
      customer.password = _hashPassword(customer.password);

      final result = await _userDao.insertUser(customer);
      return result > 0 ? null : "Không thể tạo tài khoản";
    } catch (e) {
      return "Lỗi hệ thống: $e";
    }
  }

  Future<User?> getUserProfile(String userId) async {
    return await _userDao.getUserById(userId);
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