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
}