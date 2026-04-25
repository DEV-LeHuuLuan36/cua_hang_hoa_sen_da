import 'package:flutter/material.dart';
import '../models/product/succulent.dart';
import '../models/product/category.dart';
import '../database/repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _productRepository;

  // Dữ liệu trạng thái (State)
  List<Succulent> _allProducts = [];
  List<Succulent> _filteredProducts = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Trạng thái lọc hiện tại (để giữ lại khi quay lại màn hình)
  String? _selectedCategoryId;
  String _searchQuery = '';

  // Bắt buộc nhận Repository qua Constructor
  ProductProvider({required ProductRepository productRepository})
      : _productRepository = productRepository;

  // Getters cho UI
  List<Succulent> get products => _filteredProducts;
  List<Succulent> get allProducts => _allProducts;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;

  // 1. Tải danh sách Danh mục (Categories)
  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await _productRepository.getCategories();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Tải tất cả Sản phẩm (giữ lại trạng thái lọc hiện tại)
  Future<void> loadAllProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allProducts = await _productRepository.getAllProducts();
      _applyFilters();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 3. Lọc sản phẩm theo danh mục (Dùng khi người dùng bấm vào icon danh mục)
  Future<void> loadProductsByCategory(String categoryId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final categoryProducts = await _productRepository.getProductsByCategory(categoryId);
      _allProducts = categoryProducts;
      _applyFilters();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 4. Tìm kiếm theo tên sản phẩm (không phân biệt hoa thường)
  void searchProducts(String query) {
    _searchQuery = query.trim();
    _applyFilters();
    notifyListeners();
  }

  // 5. Lọc theo danh mục từ màn Admin
  void setCategoryFilter(String? categoryId) {
    _selectedCategoryId = categoryId;
    _applyFilters();
    notifyListeners();
  }

  // 6. Xóa toàn bộ bộ lọc, quay về danh sách đầy đủ
  void clearFilters() {
    _searchQuery = '';
    _selectedCategoryId = null;
    _applyFilters();
    notifyListeners();
  }

  // Áp dụng search + category filter lên _allProducts
  void _applyFilters() {
    if (_searchQuery.isEmpty && _selectedCategoryId == null) {
      _filteredProducts = List.from(_allProducts);
      return;
    }

    _filteredProducts = _allProducts.where((p) {
      // Filter theo tên (không phân biệt hoa thường)
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase());

      // Filter theo danh mục
      final matchesCategory = _selectedCategoryId == null ||
          p.categoryId == _selectedCategoryId;

      return matchesSearch && matchesCategory;
    }).toList();
  }
  // 7. Thêm sản phẩm mới (Dùng cho Admin)
  Future<bool> addProduct(Succulent product) async {
    _isLoading = true;
    notifyListeners();

    final success = await _productRepository.addProduct(product);

    if (success) {
      // Nếu thêm thành công, load lại danh sách để màn hình cập nhật ngay
      await loadAllProducts();
    } else {
      _errorMessage = "Lỗi khi thêm sản phẩm!";
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> updateProduct(Succulent product) async {
    _isLoading = true;
    notifyListeners();

    final success = await _productRepository.updateProduct(product);

    if (success) {
      await loadAllProducts();
    } else {
      _errorMessage = "Lỗi khi cập nhật sản phẩm!";
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> deleteProduct(String productId) async {
    _isLoading = true;
    notifyListeners();

    final success = await _productRepository.deleteProduct(productId);

    if (success) {
      await loadAllProducts();
    } else {
      _errorMessage = "Lỗi khi xóa sản phẩm!";
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }
}