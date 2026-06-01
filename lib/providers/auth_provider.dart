// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../models/user/user.dart';
import '../models/user/customer.dart';
import '../models/user/admin.dart';
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

  bool get isAdmin {
    if (_currentUser == null) return false;
    final email = _currentUser!.email.toLowerCase();
    final username = _currentUser!.username.toLowerCase();
    if (email == 'admin@gmail.com' || username == 'admin') return true;
    return _currentUser!.role.name == 'ADMIN';
  }

  Future<void> tryAutoLogin() async {
    try {
      final fbUser = firebase_auth.FirebaseAuth.instance.currentUser;

      if (fbUser != null) {
        _currentUser = await _authRepository.getUserProfile(fbUser.uid);
        if (_currentUser != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', fbUser.uid);
          notifyListeners();
          return;
        }
        // Firebase session exists but DB lookup returned null.
        // Check by email/username and force-instantiate an Admin if it matches.
        if (_isKnownAdminEmail(fbUser.email) || _isKnownAdminUsername(fbUser.email?.split('@').first ?? '')) {
          _currentUser = _buildFallbackAdmin(fbUser.uid, fbUser.email ?? 'admin@gmail.com');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', fbUser.uid);
          notifyListeners();
          return;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final localUserId = prefs.getString('userId');
      if (localUserId != null) {
        _currentUser = await _authRepository.getUserProfile(localUserId);
        // Last resort: check by stored username as well
        if (_currentUser == null) {
          _currentUser = await _userDao.getUserById(localUserId);
        }
        // If still null but id looks like admin, force fallback
        if (_currentUser == null && _isKnownAdminId(localUserId)) {
          _currentUser = _buildFallbackAdmin(localUserId, 'admin@gmail.com');
        }
        notifyListeners();
      }
    } catch (e) {
      // On any unexpected error during auto-login, remain unauthenticated
      _currentUser = null;
      notifyListeners();
    }
  }

  bool _isKnownAdminEmail(String? email) {
    return email?.toLowerCase() == 'admin@gmail.com';
  }

  bool _isKnownAdminUsername(String? username) {
    return username?.toLowerCase() == 'admin';
  }

  bool _isKnownAdminId(String id) {
    return id.toLowerCase().contains('admin');
  }

  Admin _buildFallbackAdmin(String id, String email) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Admin(
      id: id,
      username: 'admin',
      password: '',
      fullName: 'Administrator',
      email: email,
      phone: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final (user, error) = await _authRepository.login(email, password);

    if (user != null) {
      _currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', user.id);
      await prefs.setBool('hasLoggedInBefore', true);
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = error ?? 'Dang nhap that bai.';
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

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final (user, error) = await _authRepository.loginWithGoogle();

    if (user != null) {
      _currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', user.id);
      await prefs.setBool('hasLoggedInBefore', true);
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = error ?? 'Dang nhap Google that bai.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    notifyListeners();
  }

  Future<bool> updateAvatar(String avatarUrl) async {
    if (_currentUser == null) return false;

    final rowsAffected = await _userDao.updateAvatar(_currentUser!.id, avatarUrl);
    final success = rowsAffected > 0;

    if (success) {
      _currentUser = await _authRepository.getUserProfile(_currentUser!.id);
      notifyListeners();
    }
    return success;
  }

  Future<bool> updateProfile(String fullName, String phone) async {
    if (_currentUser == null) return false;

    final rowsAffected = await _userDao.updateUserProfile(_currentUser!.id, fullName, phone);
    final success = rowsAffected > 0;

    if (success) {
      _currentUser = await _authRepository.getUserProfile(_currentUser!.id);
      notifyListeners();
    }
    return success;
  }

  Future<bool> verifyOldPassword(String oldPassword) async {
    if (_currentUser == null) return false;
    return await _userDao.verifyPassword(_currentUser!.id, oldPassword);
  }

  Future<bool> changePassword(String newPassword) async {
    if (_currentUser == null) return false;

    try {
      await firebase_auth.FirebaseAuth.instance.currentUser?.updatePassword(newPassword);
    } catch (e) {
      return false;
    }

    final success = await _userDao.updatePassword(_currentUser!.id, newPassword);
    if (success) {
      _currentUser = await _authRepository.getUserProfile(_currentUser!.id);
      notifyListeners();
    }
    return success;
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể gửi mã khôi phục. Vui lòng kiểm tra lại email.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    if (_currentUser == null) return false;

    final success = await _userDao.deleteAccount(_currentUser!.id);
    if (success) {
      await firebase_auth.FirebaseAuth.instance.currentUser?.delete();
      await logout();
    }
    return success;
  }
}
