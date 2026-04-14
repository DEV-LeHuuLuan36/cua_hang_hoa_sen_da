import 'package:flutter/material.dart';
import '../models/product/succulent.dart';
import '../models/product/category.dart';
import '../database/repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _productRepository;

  // Dữ liệu trạng thái (State)
  List<Succulent> _products = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Bắt buộc nhận Repository qua Constructor
  ProductProvider({required ProductRepository productRepository})
      : _productRepository = productRepository;

  // Getters cho UI
  List<Succulent> get products => _products;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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

  // 2. Tải tất cả Sản phẩm
  Future<void> loadAllProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _products = await _productRepository.getAllProducts();
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
      _products = await _productRepository.getProductsByCategory(categoryId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // 4. Thêm sản phẩm mới (Dùng cho Admin)
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
}