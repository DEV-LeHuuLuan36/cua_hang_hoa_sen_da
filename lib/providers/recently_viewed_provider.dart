import 'package:flutter/material.dart';
import '../database/daos/recently_viewed_dao.dart';

class RecentlyViewedProvider with ChangeNotifier {
  final RecentlyViewedDao recentlyViewedDao;

  RecentlyViewedProvider({required this.recentlyViewedDao});

  List<Map<String, dynamic>> _viewedProducts = [];
  List<Map<String, dynamic>> get viewedProducts => _viewedProducts;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadRecentlyViewed(String userId) async {
    _isLoading = true;
    notifyListeners();

    _viewedProducts = await recentlyViewedDao.getRecentlyViewed(userId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addViewedProduct(String userId, String productId) async {
    await recentlyViewedDao.addRecentlyViewed(userId, productId);
    await loadRecentlyViewed(userId); // Cập nhật lại UI
  }
}