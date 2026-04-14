import 'package:flutter/material.dart';
import '../models/user/user.dart';
import '../models/user/customer.dart';
import '../database/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  // Trạng thái (State)
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Bắt buộc nhận Repository từ Constructor (Decoupling Rule)
  AuthProvider({required AuthRepository authRepository})
      : _authRepository = authRepository;

  // Getters để UI đọc dữ liệu
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // 1. Logic Đăng nhập
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Báo cho UI hiện loading spinner

    final user = await _authRepository.login(username, password);

    if (user != null) {
      _currentUser = user;
      _isLoading = false;
      notifyListeners(); // Báo cho UI tắt loading, chuyển vào màn hình Home
      return true;
    } else {
      _errorMessage = "Tên đăng nhập hoặc mật khẩu không chính xác!";
      _isLoading = false;
      notifyListeners(); // Báo cho UI hiện lỗi
      return false;
    }
  }

  // 2. Logic Đăng ký (Mặc định là Customer)
  Future<bool> register(Customer customer) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final success = await _authRepository.register(customer);

    if (success) {
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = "Tên đăng nhập đã tồn tại. Vui lòng thử tên khác!";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 3. Đăng xuất
  void logout() {
    _currentUser = null;
    notifyListeners(); // Cập nhật UI bay ra màn hình Login
  }
}