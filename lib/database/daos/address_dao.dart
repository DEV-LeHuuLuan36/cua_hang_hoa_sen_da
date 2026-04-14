import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../contracts/address_contract.dart';
import '../../models/common/address.dart';

class AddressDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // 1. Thêm địa chỉ mới
  Future<int> insertAddress(Address address) async {
    final db = await _dbHelper.database;

    // Nếu địa chỉ này là mặc định, cần set các địa chỉ cũ thành không mặc định trước
    if (address.isDefault) {
      await _clearDefaultAddress(address.userId);
    }

    return await db.insert(
      AddressContract.tableName,
      address.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 2. Lấy danh sách địa chỉ của user
  Future<List<Address>> getAddressesByUser(String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AddressContract.tableName,
      where: '${AddressContract.colUserId} = ?',
      whereArgs: [userId],
      orderBy: '${AddressContract.colIsDefault} DESC, ${AddressContract.colCreatedAt} DESC', // Mặc định xếp trên cùng
    );

    return List.generate(maps.length, (i) {
      return Address.fromMap(maps[i]);
    });
  }

  // 3. Cập nhật địa chỉ
  Future<int> updateAddress(Address address) async {
    final db = await _dbHelper.database;

    if (address.isDefault) {
      await _clearDefaultAddress(address.userId);
    }

    return await db.update(
      AddressContract.tableName,
      address.toMap(),
      where: '${AddressContract.colId} = ?',
      whereArgs: [address.id],
    );
  }

  // 4. Xóa địa chỉ
  Future<int> deleteAddress(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      AddressContract.tableName,
      where: '${AddressContract.colId} = ?',
      whereArgs: [id],
    );
  }

  // Hàm phụ trợ: Set tất cả địa chỉ của user về trạng thái KHÔNG mặc định (0)
  Future<void> _clearDefaultAddress(String userId) async {
    final db = await _dbHelper.database;
    await db.update(
      AddressContract.tableName,
      {AddressContract.colIsDefault: 0},
      where: '${AddressContract.colUserId} = ?',
      whereArgs: [userId],
    );
  }
}