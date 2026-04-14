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
}