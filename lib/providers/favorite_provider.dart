import 'package:flutter/material.dart';
import '../database/daos/favorite_dao.dart';

class FavoriteProvider with ChangeNotifier {
  final FavoriteDao favoriteDao;

  FavoriteProvider({required this.favoriteDao});

  List<Map<String, dynamic>> _favoriteProducts = [];
  List<Map<String, dynamic>> get favoriteProducts => _favoriteProducts;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Tải danh sách yêu thích
  Future<void> loadFavorites(String userId) async {
    _isLoading = true;
    notifyListeners();

    _favoriteProducts = await favoriteDao.getFavoritesByUser(userId);

    _isLoading = false;
    notifyListeners();
  }

  // Bấm nút Tim
  Future<void> toggleFavorite(String userId, String productId) async {
    await favoriteDao.toggleFavorite(userId, productId);
    await loadFavorites(userId); // Load lại danh sách ngay lập tức
  }
}