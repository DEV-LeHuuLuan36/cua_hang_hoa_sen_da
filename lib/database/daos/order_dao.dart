import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../contracts/order_contract.dart';
import '../../models/order/order.dart';
import '../../models/order/order_item.dart';

class OrderDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // 1. Tạo đơn hàng mới
  Future<int> insertOrder(OrderModel order) async {
    final db = await _dbHelper.database;
    return await db.insert(
      OrderContract.tableName,
      order.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 2. Thêm sản phẩm vào chi tiết đơn hàng
  Future<int> insertOrderItem(OrderItem item) async {
    final db = await _dbHelper.database;
    return await db.insert(
      OrderItemContract.tableName,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 3. Lấy danh sách đơn hàng của một user
  Future<List<OrderModel>> getOrdersByUser(String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      OrderContract.tableName,
      where: '${OrderContract.colUserId} = ?',
      whereArgs: [userId],
      orderBy: '${OrderContract.colCreatedAt} DESC',
    );

    return List.generate(maps.length, (i) {
      return OrderModel.fromMap(maps[i]);
    });
  }

  // 4. Lấy chi tiết các sản phẩm trong một đơn hàng
  Future<List<OrderItem>> getOrderItems(String orderId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      OrderItemContract.tableName,
      where: '${OrderItemContract.colOrderId} = ?',
      whereArgs: [orderId],
    );

    return List.generate(maps.length, (i) {
      return OrderItem.fromMap(maps[i]);
    });
  }

  // 5. Cập nhật trạng thái đơn hàng (Dùng cho Admin hoặc khi thanh toán xong)
  Future<int> updateOrderStatus(String orderId, String status) async {
    final db = await _dbHelper.database;
    return await db.update(
      OrderContract.tableName,
      {
        OrderContract.colOrderStatus: status,
        OrderContract.colUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      where: '${OrderContract.colId} = ?',
      whereArgs: [orderId],
    );
  }
}