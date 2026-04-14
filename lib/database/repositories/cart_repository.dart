import '../../models/cart/cart.dart';
import '../../models/cart/cart_item.dart';
import '../daos/cart_dao.dart';

class CartRepository {
  final CartDao _cartDao;

  CartRepository({required CartDao cartDao}) : _cartDao = cartDao;

  // Lấy giỏ hàng của User, nếu chưa có thì tự động tạo mới
  Future<Cart?> getOrCreateCart(String userId) async {
    try {
      var cart = await _cartDao.getCartByUserId(userId);
      if (cart == null) {
        // Tạo giỏ hàng mới với ID là timestamp cho nhanh (trong thực tế có thể dùng thư viện UUID)
        final newCart = Cart(
          id: 'cart_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        await _cartDao.createCart(newCart);
        cart = newCart;
      }
      return cart;
    } catch (e) {
      print("Lỗi lấy/tạo giỏ hàng: $e");
      return null;
    }
  }

  // Lấy danh sách sản phẩm trong giỏ
  Future<List<CartItem>> getCartItems(String cartId) async {
    try {
      return await _cartDao.getCartItems(cartId);
    } catch (e) {
      print("Lỗi lấy sản phẩm giỏ hàng: $e");
      return [];
    }
  }

  // Thêm sản phẩm vào giỏ
  Future<bool> addToCart(CartItem item) async {
    try {
      final result = await _cartDao.insertCartItem(item);
      return result > 0;
    } catch (e) {
      print("Lỗi thêm vào giỏ: $e");
      return false;
    }
  }

  // Cập nhật số lượng (+ / -)
  Future<bool> updateQuantity(String itemId, int quantity) async {
    try {
      final result = await _cartDao.updateCartItemQuantity(itemId, quantity);
      return result > 0;
    } catch (e) {
      return false;
    }
  }

  // Xóa sản phẩm khỏi giỏ
  Future<bool> removeCartItem(String itemId) async {
    try {
      final result = await _cartDao.deleteCartItem(itemId);
      return result > 0;
    } catch (e) {
      return false;
    }
  }

  // Xóa sạch giỏ hàng (Gọi sau khi đặt hàng thành công)
  Future<bool> clearCart(String cartId) async {
    try {
      final result = await _cartDao.clearCart(cartId);
      return result > 0;
    } catch (e) {
      return false;
    }
  }
}