import 'package:flutter/material.dart';
import '../models/cart/cart.dart';
import '../models/cart/cart_item.dart';
import '../database/repositories/cart_repository.dart';

class CartProvider extends ChangeNotifier {
  final CartRepository _cartRepository;

  Cart? _cart;
  List<CartItem> _cartItems = [];
  bool _isLoading = false;

  CartProvider({required CartRepository cartRepository})
      : _cartRepository = cartRepository;

  Cart? get cart => _cart;
  List<CartItem> get cartItems => _cartItems;
  bool get isLoading => _isLoading;

  // Tổng số lượng các món trong giỏ (Dùng để hiển thị cục badge đỏ trên icon giỏ hàng)
  int get itemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  // 1. Khởi tạo và tải giỏ hàng của User (Gọi sau khi User đăng nhập thành công)
  Future<void> loadCart(String userId) async {
    _isLoading = true;
    notifyListeners();

    _cart = await _cartRepository.getOrCreateCart(userId);
    if (_cart != null) {
      _cartItems = await _cartRepository.getCartItems(_cart!.id);
    }

    _isLoading = false;
    notifyListeners();
  }

  // 2. Thêm sản phẩm vào giỏ
  Future<bool> addToCart(CartItem item) async {
    if (_cart == null) return false;

    _isLoading = true;
    notifyListeners();

    // Kiểm tra xem sản phẩm (cùng size/màu) đã có trong giỏ chưa
    final existingItemIndex = _cartItems.indexWhere((i) =>
    i.productId == item.productId && i.variant == item.variant);

    bool success;
    if (existingItemIndex >= 0) {
      // Nếu có rồi -> Tăng số lượng
      final currentItem = _cartItems[existingItemIndex];
      success = await _cartRepository.updateQuantity(
          currentItem.id, currentItem.quantity + item.quantity);
    } else {
      // Chưa có -> Thêm dòng mới
      success = await _cartRepository.addToCart(item);
    }

    // Tải lại danh sách nếu thêm thành công để UI cập nhật
    if (success) {
      _cartItems = await _cartRepository.getCartItems(_cart!.id);
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  // 3. Tăng / Giảm số lượng (+ / -)
  Future<void> updateItemQuantity(String itemId, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeItem(itemId);
      return;
    }
    final success = await _cartRepository.updateQuantity(itemId, newQuantity);
    if (success && _cart != null) {
      _cartItems = await _cartRepository.getCartItems(_cart!.id);
      notifyListeners();
    }
  }

  // 4. Xóa 1 sản phẩm khỏi giỏ (Icon thùng rác)
  Future<void> removeItem(String itemId) async {
    final success = await _cartRepository.removeCartItem(itemId);
    if (success && _cart != null) {
      _cartItems = await _cartRepository.getCartItems(_cart!.id);
      notifyListeners();
    }
  }

  // 5. Làm sạch giỏ hàng (Gọi khi đặt hàng/thanh toán thành công)
  Future<void> clearCart() async {
    if (_cart != null) {
      final success = await _cartRepository.clearCart(_cart!.id);
      if (success) {
        _cartItems.clear();
        notifyListeners();
      }
    }
  }
}