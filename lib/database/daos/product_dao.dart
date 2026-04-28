import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../contracts/product_contract.dart';
import '../../models/product/succulent.dart';

class ProductDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Thêm sản phẩm mới
  Future<int> insertProduct(Succulent product) async {
    final db = await _dbHelper.database;
    return await db.insert(
      ProductContract.tableName,
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Lấy danh sách tất cả sản phẩm (kèm ảnh chính)
  Future<List<Succulent>> getAllProducts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.*, 
             (SELECT pi.image_url FROM product_images pi 
              WHERE pi.product_id = p.id AND pi.is_primary = 1 
              LIMIT 1) as primary_image
      FROM products p
      ORDER BY p.created_at DESC
    ''');

    return List.generate(maps.length, (i) {
      return Succulent.fromMap(maps[i]);
    });
  }

  // Lấy sản phẩm theo ID (Dùng cho màn hình Chi tiết SP) [9]
  Future<Succulent?> getProductById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      ProductContract.tableName,
      where: '${ProductContract.colId} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Succulent.fromMap(maps.first);
    }
    return null;
  }

  // Lấy sản phẩm theo danh mục
  Future<List<Succulent>> getProductsByCategory(String categoryId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      ProductContract.tableName,
      where: '${ProductContract.colCategoryId} = ?',
      whereArgs: [categoryId],
    );

    return List.generate(maps.length, (i) {
      return Succulent.fromMap(maps[i]);
    });
  }

  // Cập nhật sản phẩm
  Future<int> updateProduct(Succulent product) async {
    final db = await _dbHelper.database;
    return await db.update(
      ProductContract.tableName,
      product.toMap(),
      where: '${ProductContract.colId} = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(String productId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      ProductContract.tableName,
      where: '${ProductContract.colId} = ?',
      whereArgs: [productId],
    );
  }
  Future<List<Map<String, dynamic>>> searchAndFilterProducts({
    String keyword = '',
    double? minPrice,
    double? maxPrice,
    String? careLevel,
  }) async {
    final db = await _dbHelper.database;
    final database = await db;

    // Câu lệnh SQL cơ bản
    String query = 'SELECT * FROM products WHERE name LIKE ?';
    List<dynamic> args = ['%$keyword%'];

    // Lọc theo giá tối thiểu
    if (minPrice != null) {
      query += ' AND price >= ?';
      args.add(minPrice);
    }

    // Lọc theo giá tối đa
    if (maxPrice != null) {
      query += ' AND price <= ?';
      args.add(maxPrice);
    }

    // Lọc theo độ khó chăm sóc
    if (careLevel != null && careLevel.isNotEmpty) {
      query += ' AND care_level = ?';
      args.add(careLevel);
    }

    return await database.rawQuery(query, args);
  }

  Future<void> decrementStockInTransaction(
    Transaction txn,
    String productId,
    int quantity,
  ) async {
    final updatedRows = await txn.rawUpdate(
      '''
      UPDATE ${ProductContract.tableName}
      SET ${ProductContract.colStock} = ${ProductContract.colStock} - ?,
          ${ProductContract.colUpdatedAt} = ?
      WHERE ${ProductContract.colId} = ?
        AND ${ProductContract.colStock} >= ?
      ''',
      [quantity, DateTime.now().millisecondsSinceEpoch, productId, quantity],
    );

    if (updatedRows == 0) {
      throw Exception('Không đủ tồn kho cho sản phẩm: $productId');
    }
  }

  // Đếm sản phẩm sắp hết hàng (stock < threshold)
  Future<int> countLowStockProducts({int threshold = 5}) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${ProductContract.tableName} WHERE ${ProductContract.colStock} < ?',
      [threshold],
    );
    return (result.first['count'] as int?) ?? 0;
  }
}