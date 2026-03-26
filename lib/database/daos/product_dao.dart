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

  // Lấy danh sách tất cả sản phẩm
  Future<List<Succulent>> getAllProducts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      ProductContract.tableName,
      orderBy: '${ProductContract.colCreatedAt} DESC',
    );

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
}