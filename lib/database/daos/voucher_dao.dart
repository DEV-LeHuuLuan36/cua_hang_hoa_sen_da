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
      whereArgs: [code.toUpperCase()],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllVouchers() async {
    final db = await _dbHelper.database;
    return await db.query(
      VoucherContract.tableName,
      orderBy: '${VoucherContract.colCreatedAt} DESC',
    );
  }

  /// Lấy tất cả voucher đang hoạt động (bao gồm cả hết hạn để hiển thị trạng thái)
  Future<List<Map<String, dynamic>>> getAllActiveVouchers() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return await db.query(
      VoucherContract.tableName,
      where: '${VoucherContract.colStatus} = ? AND ${VoucherContract.colStartDate} <= ?',
      whereArgs: ['ACTIVE', now],
      orderBy: '${VoucherContract.colCreatedAt} DESC',
    );
  }

  /// Lấy voucher giảm giá đang hoạt động
  Future<List<Map<String, dynamic>>> getActiveDiscountVouchers() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return await db.query(
      VoucherContract.tableName,
      where: '${VoucherContract.colStatus} = ? AND ${VoucherContract.colVoucherType} = ? AND ${VoucherContract.colStartDate} <= ?',
      whereArgs: ['ACTIVE', 'discount', now],
      orderBy: '${VoucherContract.colCreatedAt} DESC',
    );
  }

  /// Lấy voucher freeship đang hoạt động
  Future<List<Map<String, dynamic>>> getActiveShippingVouchers() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return await db.query(
      VoucherContract.tableName,
      where: '${VoucherContract.colStatus} = ? AND ${VoucherContract.colVoucherType} = ? AND ${VoucherContract.colStartDate} <= ?',
      whereArgs: ['ACTIVE', 'shipping', now],
      orderBy: '${VoucherContract.colCreatedAt} DESC',
    );
  }

  Future<int> getRemainingUsage(String voucherId) async {
    final voucher = await getVoucherById(voucherId);
    if (voucher == null) return 0;
    final quantity = voucher[VoucherContract.colQuantity] ?? 0;
    final usedCount = voucher[VoucherContract.colUsedCount] ?? 0;
    return quantity - usedCount;
  }

  /// Kiểm tra voucher có còn lượt sử dụng không
  bool hasRemainingUsage(Map<String, dynamic> voucher) {
    final quantity = voucher[VoucherContract.colQuantity] as int? ?? 0;
    final usedCount = voucher[VoucherContract.colUsedCount] as int? ?? 0;
    return usedCount < quantity;
  }

  /// Kiểm tra voucher có đang trong thời hạn không
  bool isWithinDateRange(Map<String, dynamic> voucher) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final startDate = voucher[VoucherContract.colStartDate] as int? ?? 0;
    final endDate = voucher[VoucherContract.colEndDate] as int?;
    
    // Nếu endDate là null -> không thời hạn, luôn valid
    if (endDate == null) return now >= startDate;
    
    return now >= startDate && now <= endDate;
  }

  /// Kiểm tra voucher có hết hạn chưa
  bool isExpired(Map<String, dynamic> voucher) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final endDate = voucher[VoucherContract.colEndDate] as int?;
    
    // Nếu endDate là null -> không thời hạn, chưa hết hạn
    if (endDate == null) return false;
    
    return now > endDate;
  }

  /// Kiểm tra voucher đã hết lượt chưa
  bool isUsageExhausted(Map<String, dynamic> voucher) {
    final quantity = voucher[VoucherContract.colQuantity] as int? ?? 0;
    final usedCount = voucher[VoucherContract.colUsedCount] as int? ?? 0;
    return usedCount >= quantity;
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

    final status = voucher[VoucherContract.colStatus] ?? '';
    if (status != 'ACTIVE') return false;
    if (!isWithinDateRange(voucher)) return false;
    if (isUsageExhausted(voucher)) return false;

    return true;
  }

  /// Validate voucher với thông báo lỗi chi tiết
  Future<VoucherValidationResult> validateVoucher({
    required String code,
    required double totalAmount,
  }) async {
    // Tìm voucher theo mã
    final voucher = await getVoucherByCode(code);
    if (voucher == null) {
      return VoucherValidationResult(
        isValid: false,
        errorMessage: 'Mã giảm giá không tồn tại',
      );
    }

    final voucherId = voucher[VoucherContract.colId] as String;

    // 1. Kiểm tra isActive
    final status = voucher[VoucherContract.colStatus] ?? '';
    if (status != 'ACTIVE') {
      return VoucherValidationResult(
        isValid: false,
        errorMessage: 'Mã giảm giá đã bị vô hiệu hóa',
        voucher: voucher,
      );
    }

    // 2. Kiểm tra thời hạn - chưa có hiệu lực
    final now = DateTime.now().millisecondsSinceEpoch;
    final startDate = voucher[VoucherContract.colStartDate] as int? ?? 0;
    if (now < startDate) {
      return VoucherValidationResult(
        isValid: false,
        errorMessage: 'Mã giảm giá chưa có hiệu lực',
        voucher: voucher,
      );
    }
    
    // 3. Kiểm tra hết hạn
    if (isExpired(voucher)) {
      return VoucherValidationResult(
        isValid: false,
        errorMessage: 'Mã giảm giá đã hết hạn',
        voucher: voucher,
      );
    }

    // 4. Kiểm tra số lượng sử dụng
    if (isUsageExhausted(voucher)) {
      return VoucherValidationResult(
        isValid: false,
        errorMessage: 'Mã giảm giá đã hết lượt sử dụng',
        voucher: voucher,
      );
    }

    // 5. Kiểm tra đơn hàng tối thiểu
    final minOrderValue = (voucher[VoucherContract.colMinOrderValue] as num?)?.toDouble() ?? 0;
    if (totalAmount < minOrderValue) {
      return VoucherValidationResult(
        isValid: false,
        errorMessage: 'Đơn hàng chưa đạt mức tối thiểu ${_formatMoney(minOrderValue)}',
        voucher: voucher,
      );
    }

    return VoucherValidationResult(
      isValid: true,
      voucher: voucher,
    );
  }

  Future<bool> insertVoucher(Map<String, dynamic> voucher) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    voucher[VoucherContract.colCreatedAt] = now;
    voucher[VoucherContract.colUpdatedAt] = now;
    voucher[VoucherContract.colUsedCount] = 0;
    
    final rows = await db.insert(
      VoucherContract.tableName,
      voucher,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return rows > 0;
  }

  Future<bool> updateVoucher(String id, Map<String, dynamic> data) async {
    final db = await _dbHelper.database;
    data[VoucherContract.colUpdatedAt] = DateTime.now().millisecondsSinceEpoch;
    
    final rows = await db.update(
      VoucherContract.tableName,
      data,
      where: '${VoucherContract.colId} = ?',
      whereArgs: [id],
    );
    return rows > 0;
  }

  Future<bool> toggleVoucherStatus(String id, bool isActive) async {
    return await updateVoucher(id, {
      VoucherContract.colStatus: isActive ? 'ACTIVE' : 'INACTIVE',
    });
  }

  Future<bool> deleteVoucher(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.delete(
      VoucherContract.tableName,
      where: '${VoucherContract.colId} = ?',
      whereArgs: [id],
    );
    return rows > 0;
  }

  String _formatMoney(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return '${value.toInt()}đ';
  }
}

class VoucherValidationResult {
  final bool isValid;
  final String? errorMessage;
  final Map<String, dynamic>? voucher;

  VoucherValidationResult({
    required this.isValid,
    this.errorMessage,
    this.voucher,
  });
}
