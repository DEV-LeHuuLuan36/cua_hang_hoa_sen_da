import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';

class FavoriteDao {
  Future<Database> get db async => await DatabaseHelper.instance.database;

  // 1. Thêm hoặc Bỏ yêu thích (Toggle)
  Future<bool> toggleFavorite(String userId, String productId) async {
    final database = await db;
    // Kiểm tra xem đã tim chưa
    final existing = await database.query('favorites', where: 'user_id = ? AND product_id = ?', whereArgs: [userId, productId]);

    if (existing.isNotEmpty) {
      // Đã tim rồi -> Bấm lại là Xóa
      await database.delete('favorites', where: 'id = ?', whereArgs: [existing.first['id']]);
      return false; // Trả về false nghĩa là đã Bỏ tim
    } else {
      // Chưa tim -> Thêm mới
      await database.insert('favorites', {
        'id': 'fav_${DateTime.now().millisecondsSinceEpoch}',
        'user_id': userId,
        'product_id': productId,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      return true; // Trả về true nghĩa là Đã tim
    }
  }

  // 2. Lấy danh sách sản phẩm yêu thích (JOIN với products)
  Future<List<Map<String, dynamic>>> getFavoritesByUser(String userId) async {
    final database = await db;
    return await database.rawQuery('''
      SELECT p.*, f.id as favorite_id
      FROM favorites f
      JOIN products p ON f.product_id = p.id
      WHERE f.user_id = ?
      ORDER BY f.created_at DESC
    ''', [userId]);
  }
}