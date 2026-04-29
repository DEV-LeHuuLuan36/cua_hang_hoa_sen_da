import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';

class RecentlyViewedDao {
  Future<Database> get db async => await DatabaseHelper.instance.database;

  // Lưu lịch sử xem (Nếu đã xem rồi thì cập nhật giờ mới nhất)
  Future<void> addRecentlyViewed(String userId, String productId) async {
    final database = await db;
    final existing = await database.query('recently_viewed', where: 'user_id = ? AND product_id = ?', whereArgs: [userId, productId]);

    final currentTime = DateTime.now().millisecondsSinceEpoch;

    if (existing.isNotEmpty) {
      await database.update('recently_viewed', {'viewed_at': currentTime}, where: 'id = ?', whereArgs: [existing.first['id']]);
    } else {
      await database.insert('recently_viewed', {
        'id': 'rv_$currentTime',
        'user_id': userId,
        'product_id': productId,
        'viewed_at': currentTime,
      });
    }
  }

  // Lấy 20 sản phẩm xem gần nhất (JOIN với products và product_images)
  Future<List<Map<String, dynamic>>> getRecentlyViewed(String userId) async {
    final database = await db;
    return await database.rawQuery('''
      SELECT p.*, r.viewed_at, pi.image_url as primary_image
      FROM recently_viewed r
      JOIN products p ON r.product_id = p.id
      LEFT JOIN product_images pi ON p.id = pi.product_id AND pi.is_primary = 1
      WHERE r.user_id = ?
      ORDER BY r.viewed_at DESC
      LIMIT 20
    ''', [userId]);
  }
}