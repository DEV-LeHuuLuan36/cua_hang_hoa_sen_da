import 'package:flutter/material.dart';
import '../database/repositories/order_repository.dart';

class OrderProvider with ChangeNotifier {
  final OrderRepository orderRepository;

  OrderProvider({required this.orderRepository});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _myOrders = [];
  List<Map<String, dynamic>> get myOrders => _myOrders;

  // Hàm Đặt hàng
  Future<bool> placeOrder({
    required String userId,
    required String cartId,
    required List<Map<String, dynamic>> cartItems,
    required double totalAmount,
  }) async {
    _isLoading = true;
    notifyListeners();

    final String orderId = 'ord_${DateTime.now().millisecondsSinceEpoch}';
    final orderMap = {
      'id': orderId,
      'order_number': 'SD${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      'user_id': userId,
      'address_id': 'mock_address_123',
      'subtotal': totalAmount,
      'shipping_fee': 30000.0,
      'discount': 0.0,
      'total': totalAmount + 30000.0,
      'payment_method': 'COD',
      'order_status': 'PENDING',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };

    List<Map<String, dynamic>> orderItemsMap = cartItems.map((item) {
      return {
        'id': 'oi_${DateTime.now().millisecondsSinceEpoch}_${item['product_id']}',
        'order_id': orderId,
        'product_id': item['product_id'],
        'product_name': 'Sản phẩm từ Giỏ',
        'quantity': item['quantity'],
        'price': 0.0,
        'total': 0.0,
      };
    }).toList();

    // SỬA LỖI Ở ĐÂY: Gọi thông qua Repository thay vì chọc thẳng vào DAO
    final success = await orderRepository.createOrder(orderMap, orderItemsMap, cartId);

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> loadMyOrders(String userId) async {
    _isLoading = true;
    notifyListeners();
    // SỬA LỖI Ở ĐÂY
    _myOrders = await orderRepository.getOrdersByUser(userId);
    _isLoading = false;
    notifyListeners();
  }
}