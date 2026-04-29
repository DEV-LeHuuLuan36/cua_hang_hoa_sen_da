import '../../models/product/succulent.dart';
import '../../models/product/category.dart';
import '../daos/product_dao.dart';
import '../daos/category_dao.dart';

class ProductRepository {
  final ProductDao _productDao;
  final CategoryDao _categoryDao;

  ProductRepository({
    required ProductDao productDao,
    required CategoryDao categoryDao,
  })  : _productDao = productDao,
        _categoryDao = categoryDao;

  // --- NGHIỆP VỤ DANH MỤC ---
  Future<List<Category>> getCategories() async {
    try {
      return await _categoryDao.getAllCategories();
    } catch (e) {
      print("Lỗi lấy danh mục: $e");
      return [];
    }
  }

  Future<bool> addCategory(Category category) async {
    try {
      final result = await _categoryDao.insertCategory(category);
      return result > 0;
    } catch (e) {
      return false;
    }
  }

  // --- NGHIỆP VỤ SẢN PHẨM ---
  Future<List<Succulent>> getAllProducts() async {
    try {
      return await _productDao.getAllProducts();
    } catch (e) {
      print("Lỗi lấy danh sách sản phẩm: $e");
      return [];
    }
  }

  Future<Succulent?> getProductById(String id) async {
    try {
      return await _productDao.getProductById(id);
    } catch (e) {
      print("Lỗi lấy chi tiết sản phẩm: $e");
      return null;
    }
  }

  Future<List<Succulent>> getProductsByCategory(String categoryId) async {
    try {
      return await _productDao.getProductsByCategory(categoryId);
    } catch (e) {
      return [];
    }
  }

  // Dùng cho Admin thêm sản phẩm
  Future<bool> addProduct(Succulent product) async {
    try {
      final result = await _productDao.insertProduct(product);
      return result > 0;
    } catch (e) {
      print("Lỗi thêm sản phẩm: $e");
      return false;
    }
  }

  Future<bool> updateProduct(Succulent product) async {
    try {
      final result = await _productDao.updateProduct(product);
      return result > 0;
    } catch (e) {
      print("Lỗi cập nhật sản phẩm: $e");
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      final result = await _productDao.deleteProduct(productId);
      return result > 0;
    } catch (e) {
      print("Lỗi xóa sản phẩm: $e");
      return false;
    }
  }
  Future<List<Succulent>> searchProducts({
    String keyword = '',
    double? minPrice,
    double? maxPrice,
    String? careLevel,
  }) async {
    final List<Map<String, dynamic>> maps = await _productDao.searchAndFilterProducts(
      keyword: keyword,
      minPrice: minPrice,
      maxPrice: maxPrice,
      careLevel: careLevel,
    );
    return maps.map((map) => Succulent.fromMap(map)).toList();
  }

  Future<Succulent?> refreshProduct(String productId) async {
    try {
      return await _productDao.getProductById(productId);
    } catch (e) {
      print("Lỗi refresh sản phẩm: $e");
      return null;
    }
  }
}