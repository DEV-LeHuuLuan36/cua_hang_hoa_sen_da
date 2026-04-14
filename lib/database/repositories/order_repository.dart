import '../daos/order_dao.dart';

class OrderRepository {
  final OrderDao orderDao;

  OrderRepository({required this.orderDao});

  // Cầu nối tạo đơn hàng
  Future<bool> createOrder(Map<String, dynamic> orderMap, List<Map<String, dynamic>> orderItemsMap, String cartId) async {
    return await orderDao.createOrder(orderMap, orderItemsMap, cartId);
  }

  // Cầu nối lấy danh sách đơn hàng
  Future<List<Map<String, dynamic>>> getOrdersByUser(String userId) async {
    return await orderDao.getOrdersByUser(userId);
  }
  // Cầu nối lấy TẤT CẢ đơn hàng (Admin)
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    return await orderDao.getAllOrders();
  }

  // Cầu nối cập nhật trạng thái đơn hàng (Admin)
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    final result = await orderDao.updateOrderStatus(orderId, newStatus);
    return result > 0;
  }
  // Lấy 1 đơn hàng
  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    return await orderDao.getOrderById(orderId);
  }

  // Lấy danh sách item của đơn hàng
  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    return await orderDao.getOrderItems(orderId);
  }
}