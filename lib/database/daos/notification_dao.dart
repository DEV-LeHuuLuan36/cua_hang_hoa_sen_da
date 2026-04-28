import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../contracts/notification_contract.dart';

class NotificationDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Database> get _db async => await _dbHelper.database;

  Future<int> insertNotification({
    required String id,
    required String title,
    String? body,
    String? payload,
  }) async {
    final db = await _db;
    return await db.insert(
      NotificationContract.tableName,
      {
        NotificationContract.colId: id,
        NotificationContract.colTitle: title,
        NotificationContract.colBody: body,
        NotificationContract.colPayload: payload,
        NotificationContract.colIsRead: 0,
        NotificationContract.colCreatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getNotifications({int limit = 50}) async {
    final db = await _db;
    return await db.query(
      NotificationContract.tableName,
      orderBy: '${NotificationContract.colCreatedAt} DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> getUnreadNotifications() async {
    final db = await _db;
    return await db.query(
      NotificationContract.tableName,
      where: '${NotificationContract.colIsRead} = ?',
      whereArgs: [0],
      orderBy: '${NotificationContract.colCreatedAt} DESC',
    );
  }

  Future<int> markAsRead(String id) async {
    final db = await _db;
    return await db.update(
      NotificationContract.tableName,
      {NotificationContract.colIsRead: 1},
      where: '${NotificationContract.colId} = ?',
      whereArgs: [id],
    );
  }

  Future<int> markAllAsRead() async {
    final db = await _db;
    return await db.update(
      NotificationContract.tableName,
      {NotificationContract.colIsRead: 1},
      where: '${NotificationContract.colIsRead} = ?',
      whereArgs: [0],
    );
  }

  Future<int> countUnread() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${NotificationContract.tableName} WHERE ${NotificationContract.colIsRead} = 0',
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> deleteNotification(String id) async {
    final db = await _db;
    return await db.delete(
      NotificationContract.tableName,
      where: '${NotificationContract.colId} = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAll() async {
    final db = await _db;
    return await db.delete(NotificationContract.tableName);
  }
}
