import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../contracts/review_contract.dart';
import '../contracts/product_contract.dart';

class ReviewDao {
  Future<Database> get db async => await DatabaseHelper.instance.database;

  Future<bool> submitReview({
    required String userId,
    required String productId,
    required String orderId,
    required String orderItemId,
    required int rating,
    String? comment,
  }) async {
    final database = await db;
    final now = DateTime.now().millisecondsSinceEpoch;

    try {
      await database.transaction((txn) async {
        // 1. Insert vào bảng reviews
        final reviewId = 'rev_$now';
        await txn.insert(ReviewContract.tableName, {
          ReviewContract.colId: reviewId,
          ReviewContract.colUserId: userId,
          ReviewContract.colProductId: productId,
          ReviewContract.colOrderId: orderId,
          ReviewContract.colRating: rating,
          ReviewContract.colComment: comment,
          ReviewContract.colCreatedAt: now,
          ReviewContract.colUpdatedAt: now,
        });

        // 2. Đánh dấu order_item là đã đánh giá
        await txn.update(
          'order_items',
          {'is_reviewed': 1},
          where: 'id = ?',
          whereArgs: [orderItemId],
        );

        // 3. Cập nhật lại rating trung bình và review_count trong bảng products
        // Sử dụng subquery để tính trung bình cộng số sao từ bảng reviews
        await txn.rawUpdate('''
          UPDATE ${ProductContract.tableName}
          SET ${ProductContract.colRating} = (
            SELECT AVG(${ReviewContract.colRating})
            FROM ${ReviewContract.tableName}
            WHERE ${ReviewContract.colProductId} = ?
          ),
          ${ProductContract.colReviewCount} = (
            SELECT COUNT(*)
            FROM ${ReviewContract.tableName}
            WHERE ${ReviewContract.colProductId} = ?
          ),
          ${ProductContract.colUpdatedAt} = ?
          WHERE ${ProductContract.colId} = ?
        ''', [productId, productId, now, productId]);
      });
      return true;
    } catch (e) {
      print('Lỗi submit review: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getReviewsByUser(String userId) async {
    final database = await db;
    return await database.rawQuery('''
      SELECT r.*, p.name as product_name, pi.image_url as primary_image
      FROM ${ReviewContract.tableName} r
      JOIN products p ON r.${ReviewContract.colProductId} = p.id
      LEFT JOIN product_images pi ON p.id = pi.product_id AND pi.is_primary = 1
      WHERE r.${ReviewContract.colUserId} = ?
      ORDER BY r.${ReviewContract.colCreatedAt} DESC
    ''', [userId]);
  }

  Future<List<Map<String, dynamic>>> getReviewsByProduct(String productId, {int? ratingFilter}) async {
    final database = await db;

    String sql = '''
      SELECT r.*, u.full_name, u.avatar
      FROM ${ReviewContract.tableName} r
      JOIN users u ON r.${ReviewContract.colUserId} = u.id
    ''';

    List<dynamic> args = [];

    if (ratingFilter != null && ratingFilter >= 1 && ratingFilter <= 5) {
      sql += ' WHERE r.${ReviewContract.colProductId} = ? AND r.${ReviewContract.colRating} = ?';
      args = [productId, ratingFilter];
    } else {
      sql += ' WHERE r.${ReviewContract.colProductId} = ?';
      args = [productId];
    }

    sql += ' ORDER BY r.${ReviewContract.colCreatedAt} DESC';

    return await database.rawQuery(sql, args);
  }
}
