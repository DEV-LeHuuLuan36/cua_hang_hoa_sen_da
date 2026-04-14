import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';

class OrderDao {
  Future<Database> get db async => await DatabaseHelper.instance.database;

  // 1. Tạo đơn hàng (Dùng Transaction để đảm bảo tính toàn vẹn)
  Future<bool> createOrder(
      Map<String, dynamic> orderMap,
      List<Map<String, dynamic>> orderItemsMap,
      String cartId) async {
    final database = await db;

    try {
      await database.transaction((txn) async {
        // 1.1 Insert bảng orders [1]
        await txn.insert('orders', orderMap);

        // 1.2 Insert bảng order_items [2]
        for (var item in orderItemsMap) {
          await txn.insert('order_items', item);
        }

        // 1.3 Xóa các item trong giỏ hàng (cart_items) [3]
        await txn.delete('cart_items', where: 'cart_id = ?', whereArgs: [cartId]);
      });
      return true;
    } catch (e) {
      print('Lỗi tạo đơn hàng: $e');
      return false;
    }
  }
  // 2. Lấy danh sách đơn hàng của user [1]
  Future<List<Map<String, dynamic>>> getOrdersByUser(String userId) async {
    final database = await db;
    return await database.query(
      'orders',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }
  // 3. Lấy TẤT CẢ đơn hàng (Dành cho Admin)
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    final database = await db;
    return await database.query(
      'orders',
      orderBy: 'created_at DESC', // Đơn mới nhất xếp trên
    );
  }

  // 4. Cập nhật trạng thái đơn hàng (Dành cho Admin)
  Future<int> updateOrderStatus(String orderId, String newStatus) async {
    final database = await db;
    return await database.update(
      'orders',
      {
        'order_status': newStatus,
        'updated_at': DateTime.now().millisecondsSinceEpoch
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }
  // 5. Lấy thông tin chung của 1 đơn hàng theo ID
  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    final database = await db;
    final result = await database.query(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // 6. Lấy danh sách sản phẩm (items) bên trong đơn hàng đó
  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    final database = await db;
    return await database.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
  }
}