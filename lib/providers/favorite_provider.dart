import 'package:flutter/material.dart';
import '../database/daos/favorite_dao.dart';
import '../models/product/succulent.dart';

class FavoriteProvider with ChangeNotifier {
  final FavoriteDao favoriteDao;
  List<Succulent> _favoriteProducts = [];
  bool _isLoading = false;

  FavoriteProvider({required this.favoriteDao});

  List<Succulent> get favoriteProducts => _favoriteProducts;
  bool get isLoading => _isLoading;

  bool isFavorite(String productId) {
    return _favoriteProducts.any((p) => p.id == productId);
  }

  Future<void> fetchFavorites(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Lấy dữ liệu Map thô từ SQLite
      final List<Map<String, dynamic>> rawData = await favoriteDao.getFavoritesByUser(userId);

      // 2. Chuyển đổi Map thành danh sách Object Succulent
      _favoriteProducts = rawData.map((map) => Succulent.fromMap(map)).toList();
    } catch (e) {
      debugPrint("Lỗi tải Wishlist: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(String userId, Succulent product) async {
    final existingIndex = _favoriteProducts.indexWhere((p) => p.id == product.id);

    if (existingIndex >= 0) {
      // Đã có -> Xóa khỏi DB
      final success = await favoriteDao.removeFavorite(userId, product.id);
      if (success) {
        _favoriteProducts.removeAt(existingIndex);
        notifyListeners();
      }
    } else {
      // Chưa có -> Thêm vào DB
      final success = await favoriteDao.addFavorite(userId, product.id);
      if (success) {
        _favoriteProducts.add(product);
        notifyListeners();
      }
    }
  }
}