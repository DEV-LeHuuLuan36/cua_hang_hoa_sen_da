import 'package:flutter/material.dart';
import '../models/product/succulent.dart';
import '../database/repositories/product_repository.dart';

class SearchProvider with ChangeNotifier {
  final ProductRepository productRepository;

  SearchProvider({required this.productRepository});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Succulent> _searchResults = [];
  List<Succulent> get searchResults => _searchResults;

  // Lưu trữ các điều kiện lọc hiện tại
  String _currentKeyword = '';
  double? _minPrice;
  double? _maxPrice;
  String? _careLevel;

  // Lấy giá trị filter hiện tại để hiển thị trên UI
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  String? get careLevel => _careLevel;

  Future<void> searchProducts(String keyword) async {
    _currentKeyword = keyword;
    await _executeSearch();
  }

  Future<void> applyFilter({double? minPrice, double? maxPrice, String? careLevel}) async {
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _careLevel = careLevel;
    await _executeSearch();
  }

  Future<void> clearFilter() async {
    _minPrice = null;
    _maxPrice = null;
    _careLevel = null;
    await _executeSearch();
  }

  Future<void> _executeSearch() async {
    _isLoading = true;
    notifyListeners();

    _searchResults = await productRepository.searchProducts(
      keyword: _currentKeyword,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      careLevel: _careLevel,
    );

    _isLoading = false;
    notifyListeners();
  }
}