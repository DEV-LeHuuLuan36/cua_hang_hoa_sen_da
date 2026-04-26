import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../contracts/voucher_contract.dart';

class VoucherDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Map<String, dynamic>?> getVoucherById(String id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      VoucherContract.tableName,
      where: '${VoucherContract.colId} = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getVoucherByCode(String code) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      VoucherContract.tableName,
      where: '${VoucherContract.colCode} = ?',
      whereArgs: [code],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllActiveVouchers() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return await db.query(
      VoucherContract.tableName,
      where: '${VoucherContract.colStatus} = ? AND ${VoucherContract.colStartDate} <= ? AND ${VoucherContract.colEndDate} >= ?',
      whereArgs: ['ACTIVE', now, now],
    );
  }

  Future<int> getRemainingUsage(String voucherId) async {
    final voucher = await getVoucherById(voucherId);
    if (voucher == null) return 0;
    final quantity = voucher[VoucherContract.colQuantity] ?? 0;
    final usedCount = voucher[VoucherContract.colUsedCount] ?? 0;
    return quantity - usedCount;
  }

  Future<bool> decrementUsageLimit(String voucherId) async {
    final db = await _dbHelper.database;
    final remaining = await getRemainingUsage(voucherId);
    if (remaining <= 0) return false;

    final updatedRows = await db.rawUpdate('''
      UPDATE ${VoucherContract.tableName}
      SET ${VoucherContract.colUsedCount} = ${VoucherContract.colUsedCount} + 1,
          ${VoucherContract.colUpdatedAt} = ?
      WHERE ${VoucherContract.colId} = ?
    ''', [DateTime.now().millisecondsSinceEpoch, voucherId]);

    return updatedRows > 0;
  }

  Future<bool> isVoucherValid(String voucherId) async {
    final voucher = await getVoucherById(voucherId);
    if (voucher == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final startDate = voucher[VoucherContract.colStartDate] ?? 0;
    final endDate = voucher[VoucherContract.colEndDate] ?? 0;
    final status = voucher[VoucherContract.colStatus] ?? '';
    final remaining = await getRemainingUsage(voucherId);

    return status == 'ACTIVE' &&
           now >= startDate &&
           now <= endDate &&
           remaining > 0;
  }
}
