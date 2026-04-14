import 'package:flutter/material.dart';
import '../models/order/order.dart';
import '../models/order/order_item.dart';
import '../database/repositories/order_repository.dart';

class OrderProvider extends ChangeNotifier {
  final OrderRepository _orderRepository;

  List<OrderModel> _orders = [];
  bool _isLoading = false;

  // Bắt buộc nhận Repository qua Constructor để đảm bảo Decoupling
  OrderProvider({required OrderRepository orderRepository})
      : _orderRepository = orderRepository;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  // 1. Lấy danh sách lịch sử đơn hàng của User
  Future<void> loadUserOrders(String userId) async {
    _isLoading = true;
    notifyListeners();

    _orders = await _orderRepository.getOrdersByUser(userId);

    _isLoading = false;
    notifyListeners();
  }

  // 2. Tạo đơn hàng mới (Khi nhấn Thanh toán)
  Future<bool> createOrder(OrderModel order, List<OrderItem> items) async {
    _isLoading = true;
    notifyListeners();

    final success = await _orderRepository.createOrder(order, items);

    if (success) {
      // Tải lại danh sách đơn hàng để cập nhật trạng thái mới nhất
      _orders = await _orderRepository.getOrdersByUser(order.userId);
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }
}
