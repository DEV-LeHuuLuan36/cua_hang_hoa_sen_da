import 'package:flutter/material.dart'; // Thêm dòng này để dùng debugPrint
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';

class FavoriteDao {
  // Đường ống chuẩn để gọi database của bạn
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

  // 3. Hàm thêm sản phẩm vào danh sách yêu thích
  Future<bool> addFavorite(String userId, String productId) async {
    try {
      final database = await db; // <-- ĐÃ SỬA LỖI CONSTRUCTOR Ở ĐÂY

      await database.insert('favorites', {
        'id': 'fav_${DateTime.now().millisecondsSinceEpoch}', // Đã bổ sung ID cho chuẩn với cấu trúc bảng
        'user_id': userId,
        'product_id': productId,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      debugPrint('Lỗi thêm yêu thích: $e');
      return false;
    }
  }

  // 4. Hàm xóa sản phẩm khỏi danh sách yêu thích
  Future<bool> removeFavorite(String userId, String productId) async {
    try {
      final database = await db; // <-- ĐÃ SỬA LỖI CONSTRUCTOR Ở ĐÂY

      await database.delete(
        'favorites',
        where: 'user_id = ? AND product_id = ?',
        whereArgs: [userId, productId],
      );
      return true;
    } catch (e) {
      debugPrint('Lỗi xóa yêu thích: $e');
      return false;
    }
  }
}