import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../contracts/cart_contract.dart';
import '../../models/cart/cart.dart';
import '../../models/cart/cart_item.dart';

class CartDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // 1. Lấy hoặc tạo giỏ hàng cho User
  Future<Cart?> getCartByUserId(String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      CartContract.tableName,
      where: '${CartContract.colUserId} = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return Cart.fromMap(maps.first);
    }
    return null;
  }

  Future<int> createCart(Cart cart) async {
    final db = await _dbHelper.database;
    return await db.insert(
      CartContract.tableName,
      cart.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // 2. Thêm sản phẩm vào giỏ
  Future<int> insertCartItem(CartItem item) async {
    final db = await _dbHelper.database;
    return await db.insert(
      CartItemContract.tableName,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 3. Lấy tất cả sản phẩm trong giỏ của user
  Future<List<CartItem>> getCartItems(String cartId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      CartItemContract.tableName,
      where: '${CartItemContract.colCartId} = ?',
      whereArgs: [cartId],
      orderBy: '${CartItemContract.colAddedAt} DESC',
    );

    return List.generate(maps.length, (i) {
      return CartItem.fromMap(maps[i]);
    });
  }

  // 4. Cập nhật số lượng sản phẩm trong giỏ
  Future<int> updateCartItemQuantity(String itemId, int newQuantity) async {
    final db = await _dbHelper.database;
    return await db.update(
      CartItemContract.tableName,
      {CartItemContract.colQuantity: newQuantity},
      where: '${CartItemContract.colId} = ?',
      whereArgs: [itemId],
    );
  }

  // 5. Xóa sản phẩm khỏi giỏ
  Future<int> deleteCartItem(String itemId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      CartItemContract.tableName,
      where: '${CartItemContract.colId} = ?',
      whereArgs: [itemId],
    );
  }

  // 6. Làm sạch giỏ hàng (Sau khi đặt hàng thành công)
  Future<int> clearCart(String cartId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      CartItemContract.tableName,
      where: '${CartItemContract.colCartId} = ?',
      whereArgs: [cartId],
    );
  }
}