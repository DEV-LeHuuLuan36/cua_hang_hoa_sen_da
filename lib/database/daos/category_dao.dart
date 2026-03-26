import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../contracts/category_contract.dart';
import '../../models/product/category.dart';

class CategoryDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Thêm danh mục mới
  Future<int> insertCategory(Category category) async {
    final db = await _dbHelper.database;
    return await db.insert(
      CategoryContract.tableName,
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Lấy toàn bộ danh mục
  Future<List<Category>> getAllCategories() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      CategoryContract.tableName,
      orderBy: '${CategoryContract.colSortOrder} ASC',
    );

    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  // Cập nhật danh mục
  Future<int> updateCategory(Category category) async {
    final db = await _dbHelper.database;
    return await db.update(
      CategoryContract.tableName,
      category.toMap(),
      where: '${CategoryContract.colId} = ?',
      whereArgs: [category.id],
    );
  }

  // Xóa danh mục
  Future<int> deleteCategory(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      CategoryContract.tableName,
      where: '${CategoryContract.colId} = ?',
      whereArgs: [id],
    );
  }
}