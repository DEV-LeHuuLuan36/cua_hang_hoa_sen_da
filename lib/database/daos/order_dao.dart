import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';

class OrderDao {
  Future<Database> get db async => await DatabaseHelper.instance.database;

  Future<void> createOrderInTransaction(
    Transaction txn,
    Map<String, dynamic> orderMap,
    List<Map<String, dynamic>> orderItemsMap,
    String cartId,
  ) async {
    await txn.insert('orders', orderMap);

    for (var item in orderItemsMap) {
      await txn.insert('order_items', item);
    }

    await txn.delete('cart_items', where: 'cart_id = ?', whereArgs: [cartId]);
  }

  // 1. Tạo đơn hàng (Dùng Transaction để đảm bảo tính toàn vẹn)
  Future<bool> createOrder(
      Map<String, dynamic> orderMap,
      List<Map<String, dynamic>> orderItemsMap,
      String cartId) async {
    final database = await db;

    try {
      await database.transaction((txn) async {
        await createOrderInTransaction(txn, orderMap, orderItemsMap, cartId);
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
  Future<List<Map<String, dynamic>>> getOrderItems(String orderId, {bool? isReviewed}) async {
    final database = await db;
    String whereClause = 'oi.order_id = ?';
    List<dynamic> whereArgs = [orderId];

    if (isReviewed != null) {
      whereClause += ' AND oi.is_reviewed = ?';
      whereArgs.add(isReviewed ? 1 : 0);
    }

    return await database.rawQuery('''
      SELECT oi.*, oi.is_reviewed, p.name as product_name, p.price, pi.image_url as primary_image
      FROM order_items oi
      JOIN products p ON oi.product_id = p.id
      LEFT JOIN product_images pi ON p.id = pi.product_id AND pi.is_primary = 1
      WHERE $whereClause
    ''', whereArgs);
  }
}