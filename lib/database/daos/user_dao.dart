import 'package:sqflite/sqflite.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
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
    // BẮT BUỘC hash password trước khi lưu
    final hashedPassword = sha256.convert(utf8.encode(newPassword)).toString();
    final updatedRows = await db.update(
      UserContract.tableName,
      {
        UserContract.colPassword: hashedPassword,
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
      columns: [UserContract.colPassword],
      where: '${UserContract.colId} = ?',
      whereArgs: [userId],
    );

    if (result.isEmpty) {
      print('UserDao verifyPassword: User not found for id: $userId');
      return false;
    }

    final dbPassword = result.first[UserContract.colPassword] as String?;
    final hashedPassword = sha256.convert(utf8.encode(password)).toString();
    print('UserDao verifyPassword: Input: "$password" | Hashed: "$hashedPassword" | DB: "$dbPassword"');

    return dbPassword == hashedPassword;
  }

  // 9. Đếm khách hàng mới theo khoảng thời gian
  Future<int> countNewCustomers(DateTime? startDate, DateTime? endDate) async {
    final db = await _dbHelper.database;
    String whereClause = '${UserContract.colRole} = ?';
    List<dynamic> whereArgs = [UserRole.CUSTOMER.name];

    if (startDate != null) {
      whereClause += ' AND ${UserContract.colCreatedAt} >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }
    if (endDate != null) {
      whereClause += ' AND ${UserContract.colCreatedAt} <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${UserContract.tableName} WHERE $whereClause',
      whereArgs,
    );
    return (result.first['count'] as int?) ?? 0;
  }

  // 10. Xóa tài khoản
  Future<bool> deleteAccount(String userId) async {
    final db = await _dbHelper.database;
    final deletedRows = await db.delete(
      UserContract.tableName,
      where: '${UserContract.colId} = ?',
      whereArgs: [userId],
    );
    return deletedRows > 0;
  }
}