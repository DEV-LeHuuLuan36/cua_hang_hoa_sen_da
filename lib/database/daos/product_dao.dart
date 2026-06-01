import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../contracts/product_contract.dart';
import '../../models/product/succulent.dart';

class ProductDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Thêm sản phẩm mới và lưu ảnh chính
  Future<int> insertProduct(Succulent product) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    batch.insert(
      ProductContract.tableName,
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (product.primaryImage != null && product.primaryImage!.isNotEmpty) {
      batch.insert(
        ProductImageContract.tableName,
        {
          ProductImageContract.colId: 'img_${product.id}_${DateTime.now().millisecondsSinceEpoch}',
          ProductImageContract.colProductId: product.id,
          ProductImageContract.colImageUrl: product.primaryImage,
          ProductImageContract.colIsPrimary: 1,
          ProductImageContract.colSortOrder: 0,
          ProductImageContract.colCreatedAt: DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final results = await batch.commit();
    return results.first as int;
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
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.*,
             (SELECT pi.image_url FROM product_images pi
              WHERE pi.product_id = p.id AND pi.is_primary = 1
              LIMIT 1) as primary_image
      FROM products p
      WHERE p.id = ?
    ''', [id]);

    if (maps.isNotEmpty) {
      return Succulent.fromMap(maps.first);
    }
    return null;
  }

  // Lấy sản phẩm theo danh mục
  Future<List<Succulent>> getProductsByCategory(String categoryId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.*,
             (SELECT pi.image_url FROM product_images pi
              WHERE pi.product_id = p.id AND pi.is_primary = 1
              LIMIT 1) as primary_image
      FROM products p
      WHERE p.category_id = ?
    ''', [categoryId]);

    return List.generate(maps.length, (i) {
      return Succulent.fromMap(maps[i]);
    });
  }

  // Cập nhật sản phẩm và ảnh chính
  Future<int> updateProduct(Succulent product) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    batch.update(
      ProductContract.tableName,
      product.toMap(),
      where: '${ProductContract.colId} = ?',
      whereArgs: [product.id],
    );

    // Xóa ảnh cũ rồi chèn lại nếu có ảnh mới
    batch.delete(
      ProductImageContract.tableName,
      where: '${ProductImageContract.colProductId} = ? AND ${ProductImageContract.colIsPrimary} = 1',
      whereArgs: [product.id],
    );

    if (product.primaryImage != null && product.primaryImage!.isNotEmpty) {
      batch.insert(
        ProductImageContract.tableName,
        {
          ProductImageContract.colId: 'img_${product.id}_${DateTime.now().millisecondsSinceEpoch}',
          ProductImageContract.colProductId: product.id,
          ProductImageContract.colImageUrl: product.primaryImage,
          ProductImageContract.colIsPrimary: 1,
          ProductImageContract.colSortOrder: 0,
          ProductImageContract.colCreatedAt: DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final results = await batch.commit();
    return results.first as int;
  }

  Future<int> deleteProduct(String productId) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    batch.delete(
      ProductImageContract.tableName,
      where: '${ProductImageContract.colProductId} = ?',
      whereArgs: [productId],
    );

    batch.delete(
      ProductContract.tableName,
      where: '${ProductContract.colId} = ?',
      whereArgs: [productId],
    );

    final results = await batch.commit();
    return results.last as int;
  }
  Future<List<Map<String, dynamic>>> searchAndFilterProducts({
    String keyword = '',
    double? minPrice,
    double? maxPrice,
    String? careLevel,
  }) async {
    final database = await _dbHelper.database;

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