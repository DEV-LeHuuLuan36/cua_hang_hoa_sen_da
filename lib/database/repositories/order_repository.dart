import '../daos/order_dao.dart';
import '../daos/product_dao.dart';
import '../contracts/order_contract.dart';
import '../database_helper.dart';

class OrderRepository {
  final OrderDao orderDao;
  final ProductDao _productDao;

  OrderRepository({
    required this.orderDao,
    ProductDao? productDao,
  }) : _productDao = productDao ?? ProductDao();

  // Cầu nối tạo đơn hàng
  Future<bool> createOrder(
    Map<String, dynamic> orderMap,
    List<Map<String, dynamic>> orderItemsMap,
    String cartId,
  ) async {
    final database = await DatabaseHelper.instance.database;

    try {
      await database.transaction((txn) async {
        await orderDao.createOrderInTransaction(txn, orderMap, orderItemsMap, cartId);

        for (final item in orderItemsMap) {
          final productId = item[OrderItemContract.colProductId]?.toString();
          final quantityRaw = item[OrderItemContract.colQuantity];
          final quantity = quantityRaw is int ? quantityRaw : int.tryParse('$quantityRaw');

          if (productId == null || quantity == null || quantity <= 0) {
            continue;
          }

          await _productDao.decrementStockInTransaction(txn, productId, quantity);
        }
      });
      return true;
    } catch (e) {
      print('Lỗi tạo đơn hàng và trừ tồn kho: $e');
      return false;
    }
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

  // Lấy danh sách item của đơn hàng (có filter theo is_reviewed)
  Future<List<Map<String, dynamic>>> getOrderItems(String orderId, {bool? isReviewed}) async {
    return await orderDao.getOrderItems(orderId, isReviewed: isReviewed);
  }
}