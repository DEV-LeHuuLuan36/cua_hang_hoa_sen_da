// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user/user.dart';
import '../models/user/customer.dart';
import '../database/repositories/auth_repository.dart';
import '../database/daos/user_dao.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserDao _userDao = UserDao();
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({required AuthRepository authRepository}) : _authRepository = authRepository;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // Tự động khôi phục session
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId != null) {
      _currentUser = await _authRepository.getUserProfile(userId);
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final user = await _authRepository.login(username, password);
    if (user != null) {
      _currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', user.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = "Sai tài khoản hoặc mật khẩu";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(Customer customer) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final error = await _authRepository.register(customer);
    if (error == null) {
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = error;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    notifyListeners();
  }

  // Cập nhật avatar
  Future<bool> updateAvatar(String avatarUrl) async {
    if (_currentUser == null) return false;

    // Đổi thành int vì UserDao trả về số dòng bị ảnh hưởng
    final int rowsAffected = await _userDao.updateAvatar(_currentUser!.id, avatarUrl);
    final bool success = rowsAffected > 0; // Nếu lớn hơn 0 nghĩa là cập nhật thành công

    if (success) {
      _currentUser = await _authRepository.getUserProfile(_currentUser!.id);
      notifyListeners();
    }
    return success;
  }

  // Cập nhật thông tin profile
  Future<bool> updateProfile(String fullName, String phone) async {
    if (_currentUser == null) return false;

    final int rowsAffected = await _userDao.updateUserProfile(_currentUser!.id, fullName, phone);
    final bool success = rowsAffected > 0;

    if (success) {
      _currentUser = await _authRepository.getUserProfile(_currentUser!.id);
      notifyListeners();
    }
    return success;
  }

  // Xác thực mật khẩu cũ
  Future<bool> verifyOldPassword(String oldPassword) async {
    if (_currentUser == null) return false;
    return await _userDao.verifyPassword(_currentUser!.id, oldPassword);
  }

  // Đổi mật khẩu
  Future<bool> changePassword(String newPassword) async {
    if (_currentUser == null) return false;

    final bool success = await _userDao.updatePassword(_currentUser!.id, newPassword);
    if (success) {
      _currentUser = await _authRepository.getUserProfile(_currentUser!.id);
      notifyListeners();
    }
    return success;
  }

  // Xóa tài khoản
  Future<bool> deleteAccount() async {
    if (_currentUser == null) return false;

    final bool success = await _userDao.deleteAccount(_currentUser!.id);
    if (success) {
      logout();
    }
    return success;
  }
}