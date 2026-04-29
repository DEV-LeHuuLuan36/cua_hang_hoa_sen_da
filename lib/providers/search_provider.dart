import 'package:flutter/material.dart';
import '../models/product/succulent.dart';
import '../models/product/category.dart';
import '../models/enums/product_status.dart';
import '../database/repositories/product_repository.dart';

class SearchProvider with ChangeNotifier {
  final ProductRepository productRepository;

  SearchProvider({required this.productRepository});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Succulent> _searchResults = [];
  List<Succulent> get searchResults => _searchResults;

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  // Lưu trữ từ khóa tìm kiếm
  String _currentKeyword = '';
  String get currentKeyword => _currentKeyword;

  // Bộ lọc
  RangeValues _priceRange = const RangeValues(0, 500000);
  RangeValues get priceRange => _priceRange;

  String? _selectedCategoryId;
  String? get selectedCategoryId => _selectedCategoryId;

  ProductStatus? _selectedStatus;
  ProductStatus? get selectedStatus => _selectedStatus;

  String? _selectedCareLevel;
  String? get selectedCareLevel => _selectedCareLevel;

  // Kiểm tra có bộ lọc nào đang áp dụng
  bool get hasActiveFilters {
    return _selectedCategoryId != null ||
        _selectedStatus != null ||
        _selectedCareLevel != null ||
        _priceRange.start > 0 ||
        _priceRange.end < 500000;
  }

  Future<void> loadCategories() async {
    _categories = await productRepository.getCategories();
    notifyListeners();
  }

  Future<void> searchProducts(String keyword) async {
    _currentKeyword = keyword;
    await applyFilter();
  }

  Future<void> applyFilter({
    RangeValues? priceRange,
    String? categoryId,
    ProductStatus? status,
    String? careLevel,
  }) async {
    if (priceRange != null) _priceRange = priceRange;
    if (categoryId != null) _selectedCategoryId = categoryId;
    if (status != null) _selectedStatus = status;
    if (careLevel != null) _selectedCareLevel = careLevel;

    await _executeSearch();
  }

  void setPriceRange(RangeValues range) {
    _priceRange = range;
    notifyListeners();
  }

  void setCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setStatus(ProductStatus? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setCareLevel(String? careLevel) {
    _selectedCareLevel = careLevel;
    notifyListeners();
  }

  Future<void> resetFilter() async {
    _priceRange = const RangeValues(0, 500000);
    _selectedCategoryId = null;
    _selectedStatus = null;
    _selectedCareLevel = null;
    await _executeSearch();
  }

  Future<void> _executeSearch() async {
    _isLoading = true;
    notifyListeners();

    // Lấy tất cả sản phẩm và lọc
    final allProducts = await productRepository.searchProducts(
      keyword: _currentKeyword,
    );

    // Áp dụng bộ lọc bổ sung
    _searchResults = allProducts.where((product) {
      // Lọc theo khoảng giá
      final price = product.salePrice ?? product.price;
      if (price < _priceRange.start || price > _priceRange.end) {
        return false;
      }

      // Lọc theo danh mục
      if (_selectedCategoryId != null && product.categoryId != _selectedCategoryId) {
        return false;
      }

      // Lọc theo trạng thái
      if (_selectedStatus != null && product.status != _selectedStatus) {
        return false;
      }

      // Lọc theo độ khó chăm sóc
      if (_selectedCareLevel != null && product.careInstruction.careLevel != _selectedCareLevel) {
        return false;
      }

      return true;
    }).toList();

    _isLoading = false;
    notifyListeners();
  }
}
