import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../contracts/user_contract.dart';
import '../../models/user/user.dart';
import '../../models/user/customer.dart';
import '../../models/user/admin.dart';
import '../../models/enums/user_role.dart';

class UserDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // 1. Thêm mới user (Đăng ký)
  Future<int> insertUser(User user) async {
    final db = await _dbHelper.database;
    return await db.insert(
      UserContract.tableName,
      user.toMap(), // Tự động map dữ liệu thành Map để lưu
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 2. Lấy thông tin user bằng ID (Dùng để load thông tin cá nhân)
  Future<User?> getUserById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      UserContract.tableName,
      where: '${UserContract.colId} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final map = maps.first;
      // Dựa vào Role để quyết định parse ra Admin hay Customer
      if (map[UserContract.colRole] == UserRole.ADMIN.name) {
        return Admin.fromMap(map);
      } else {
        return Customer.fromMap(map);
      }
    }
    return null;
  }

  // 3. Kiểm tra đăng nhập
  Future<User?> login(String username, String password) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      UserContract.tableName,
      where: '${UserContract.colUsername} = ? AND ${UserContract.colPassword} = ?',
      whereArgs: [username, password],
    );

    if (maps.isNotEmpty) {
      final map = maps.first;
      if (map[UserContract.colRole] == UserRole.ADMIN.name) {
        return Admin.fromMap(map);
      } else {
        return Customer.fromMap(map);
      }
    }
    return null;
  }

  // 4. Cập nhật thông tin User
  Future<int> updateUser(User user) async {
    final db = await _dbHelper.database;
    return await db.update(
      UserContract.tableName,
      user.toMap(),
      where: '${UserContract.colId} = ?',
      whereArgs: [user.id],
    );
  }

  // 5. Cập nhật avatar URL
  Future<int> updateAvatar(String userId, String avatarUrl) async {
    final db = await _dbHelper.database;
    return await db.update(
      UserContract.tableName,
      {
        UserContract.colAvatar: avatarUrl,
        UserContract.colUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      where: '${UserContract.colId} = ?',
      whereArgs: [userId],
    );
  }

  // 6. Cập nhật thông tin cá nhân (tên, sdt)
  Future<int> updateUserProfile(String userId, String fullName, String phone) async {
    final db = await _dbHelper.database;
    return await db.update(
      UserContract.tableName,
      {
        UserContract.colFullName: fullName,
        UserContract.colPhone: phone,
        UserContract.colUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      where: '${UserContract.colId} = ?',
      whereArgs: [userId],
    );
  }

  // 7. Cập nhật mật khẩu
  Future<bool> updatePassword(String userId, String newPassword) async {
    final db = await _dbHelper.database;
    final updatedRows = await db.update(
      UserContract.tableName,
      {
        UserContract.colPassword: newPassword,
        UserContract.colUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      where: '${UserContract.colId} = ?',
      whereArgs: [userId],
    );
    return updatedRows > 0;
  }

  // 8. Kiểm tra mật khẩu cũ
  Future<bool> verifyPassword(String userId, String password) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      UserContract.tableName,
      where: '${UserContract.colId} = ? AND ${UserContract.colPassword} = ?',
      whereArgs: [userId, password],
    );
    return result.isNotEmpty;
  }
}