import 'package:flutter/material.dart';
import '../database/repositories/order_repository.dart';

class OrderProvider with ChangeNotifier {
  final OrderRepository orderRepository;

  OrderProvider({required this.orderRepository});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _myOrders = [];
  List<Map<String, dynamic>> get myOrders => _myOrders;
  List<Map<String, dynamic>> _allOrders = [];
  List<Map<String, dynamic>> get allOrders => _allOrders;
  // Tải toàn bộ đơn hàng
  Future<void> loadAllOrders() async {
    _isLoading = true;
    notifyListeners();
    _allOrders = await orderRepository.getAllOrders();
    _isLoading = false;
    notifyListeners();
  }
  // Cập nhật trạng thái đơn hàng
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    _isLoading = true;
    notifyListeners();

    final success = await orderRepository.updateOrderStatus(orderId, newStatus);
    if (success) {
      await loadAllOrders(); // Tải lại danh sách để UI tự nhảy Tab
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }
  // Hàm Đặt hàng
  Future<bool> placeOrder({
    required String userId,
    required String cartId,
    required List<Map<String, dynamic>> cartItems,
    required double totalAmount,
    String? voucherId,            // <-- Đã thêm
    double discountAmount = 0,    // <-- Đã thêm
    double shippingFee = 30000,   // <-- Đã thêm
    String paymentMethod = 'COD', // <-- Đã thêm
  }) async {
    _isLoading = true;
    notifyListeners();

    final String orderId = 'ord_${DateTime.now().millisecondsSinceEpoch}';
    final orderMap = {
      'id': orderId,
      'order_number': 'SD${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      'user_id': userId,
      'address_id': 'mock_address_123',
      'subtotal': totalAmount - shippingFee + discountAmount, // Tính ngược lại tiền hàng gốc
      'shipping_fee': shippingFee,
      'discount': discountAmount,
      'total': totalAmount, // Số tiền khách thực trả
      'payment_method': paymentMethod, // Lấy phương thức đã chọn
      'order_status': 'PENDING',
      'voucher_id': voucherId, // Lưu ID mã giảm giá nếu có
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

    // Gọi thông qua Repository
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
  Map<String, dynamic>? _currentOrder;
  List<Map<String, dynamic>> _currentOrderItems = [];

  Map<String, dynamic>? get currentOrder => _currentOrder;
  List<Map<String, dynamic>> get currentOrderItems => _currentOrderItems;

  Future<void> loadOrderDetail(String orderId) async {
    _isLoading = true;
    notifyListeners();

    // Gọi 2 hàm Repository cùng lúc để tối ưu thời gian
    _currentOrder = await orderRepository.getOrderById(orderId);
    _currentOrderItems = await orderRepository.getOrderItems(orderId);

    _isLoading = false;
    notifyListeners();
  }
}