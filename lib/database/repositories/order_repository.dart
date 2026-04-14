import '../../models/order/order.dart';
import '../../models/order/order_item.dart';
import '../daos/order_dao.dart';

class OrderRepository {
  final OrderDao _orderDao;

  OrderRepository({required OrderDao orderDao}) : _orderDao = orderDao;

  // Tạo đơn hàng mới (Lưu cả Order tổng và các OrderItems chi tiết)
  Future<bool> createOrder(OrderModel order, List<OrderItem> items) async {
    try {
      // 1. Lưu thông tin hóa đơn tổng
      final orderResult = await _orderDao.insertOrder(order);
      if (orderResult <= 0) return false;

      // 2. Lưu từng sản phẩm vào chi tiết hóa đơn
      for (var item in items) {
        await _orderDao.insertOrderItem(item);
      }
      return true;
    } catch (e) {
      print("Lỗi tạo đơn hàng: $e");
      return false;
    }
  }

  // Lấy lịch sử đơn hàng của người dùng
  Future<List<OrderModel>> getOrdersByUser(String userId) async {
    try {
      return await _orderDao.getOrdersByUser(userId);
    } catch (e) {
      print("Lỗi lấy lịch sử đơn hàng: $e");
      return [];
    }
  }

  // Lấy chi tiết các sản phẩm của một đơn hàng cụ thể
  Future<List<OrderItem>> getOrderItems(String orderId) async {
    try {
      return await _orderDao.getOrderItems(orderId);
    } catch (e) {
      print("Lỗi lấy chi tiết sản phẩm đơn hàng: $e");
      return [];
    }
  }

  // Cập nhật trạng thái đơn (Dành cho Admin hoặc khi thanh toán online xong)
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      final result = await _orderDao.updateOrderStatus(orderId, status);
      return result > 0;
    } catch (e) {
      print("Lỗi cập nhật trạng thái đơn: $e");
      return false;
    }
  }
}