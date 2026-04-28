import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../database/daos/voucher_dao.dart';
import '../../../database/contracts/voucher_contract.dart';

class AdminVoucherScreen extends StatefulWidget {
  const AdminVoucherScreen({Key? key}) : super(key: key);

  @override
  State<AdminVoucherScreen> createState() => _AdminVoucherScreenState();
}

class _AdminVoucherScreenState extends State<AdminVoucherScreen> {
  final VoucherDao _voucherDao = VoucherDao();
  List<Map<String, dynamic>> _vouchers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    setState(() => _isLoading = true);
    try {
      final vouchers = await _voucherDao.getAllVouchers();
      setState(() {
        _vouchers = vouchers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddEditVoucherDialog({Map<String, dynamic>? voucher}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VoucherFormSheet(
        voucher: voucher,
        onSaved: () {
          _loadVouchers();
        },
      ),
    );
  }

  Future<void> _toggleVoucherStatus(Map<String, dynamic> voucher) async {
    final isActive = voucher[VoucherContract.colStatus] == 'ACTIVE';
    final voucherId = voucher[VoucherContract.colId] as String;
    
    HapticFeedback.lightImpact();
    final success = await _voucherDao.toggleVoucherStatus(voucherId, !isActive);
    
    if (success) {
      _loadVouchers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive ? 'Đã vô hiệu hóa voucher' : 'Đã kích hoạt voucher'),
            backgroundColor: isActive ? Colors.orange : AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _deleteVoucher(Map<String, dynamic> voucher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Voucher'),
        content: Text('Bạn có chắc muốn xóa voucher "${voucher[VoucherContract.colCode]}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final voucherId = voucher[VoucherContract.colId] as String;
      await _voucherDao.deleteVoucher(voucherId);
      _loadVouchers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa voucher'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản lý Voucher'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddEditVoucherDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vouchers.isEmpty
              ? _buildEmptyState()
              : _buildVoucherList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditVoucherDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Chưa có voucher nào',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _showAddEditVoucherDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Tạo voucher mới'),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherList() {
    return RefreshIndicator(
      onRefresh: _loadVouchers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _vouchers.length,
        itemBuilder: (context, index) {
          final voucher = _vouchers[index];
          return _buildVoucherCard(voucher);
        },
      ),
    );
  }

  Widget _buildVoucherCard(Map<String, dynamic> voucher) {
    final voucherType = voucher[VoucherContract.colVoucherType] ?? 'discount';
    final discountType = voucher[VoucherContract.colDiscountType] ?? '';
    final discountValue = (voucher[VoucherContract.colDiscountValue] as num?)?.toDouble() ?? 0;
    final minOrder = (voucher[VoucherContract.colMinOrderValue] as num?)?.toDouble() ?? 0;
    final maxDiscount = (voucher[VoucherContract.colMaxDiscount] as num?)?.toDouble();
    final quantity = voucher[VoucherContract.colQuantity] as int? ?? 0;
    final usedCount = voucher[VoucherContract.colUsedCount] as int? ?? 0;
    final code = voucher[VoucherContract.colCode] ?? '';
    final name = voucher[VoucherContract.colName] ?? '';
    final status = voucher[VoucherContract.colStatus] ?? '';
    final isActive = status == 'ACTIVE';
    final endDate = voucher[VoucherContract.colEndDate] as int?;
    final isNoExpiry = endDate == null;
    final endDateStr = isNoExpiry ? 'Không thời hạn' : DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(endDate));
    final isExpired = !isNoExpiry && DateTime.now().millisecondsSinceEpoch > endDate;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive && !isExpired 
              ? AppColors.primary.withValues(alpha: 0.3) 
              : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive && !isExpired
                  ? AppColors.primary.withValues(alpha: 0.05)
                  : Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: voucherType == 'shipping' ? Colors.blue : Colors.orange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        voucherType == 'shipping' ? Icons.local_shipping : Icons.percent,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        voucherType == 'shipping' ? 'SHIP' : 'GIẢM',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Discount value
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _getGradientColors(voucherType),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: voucherType == 'shipping'
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_shipping, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Freeship',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          discountType == 'percent'
                              ? '${discountValue.toInt()}%'
                              : '${(discountValue / 1000).toStringAsFixed(0)}K',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            code,
                            style: TextStyle(
                              color: isActive && !isExpired ? AppColors.primary : Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isExpired 
                                  ? AppColors.error 
                                  : isActive 
                                      ? AppColors.success 
                                      : Colors.grey,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isExpired 
                                  ? 'HẾT HẠN' 
                                  : isActive 
                                      ? 'ACTIVE' 
                                      : 'INACTIVE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Toggle switch (chỉ khi chưa hết hạn)
                if (!isExpired)
                  Switch(
                    value: isActive,
                    onChanged: (_) => _toggleVoucherStatus(voucher),
                    activeColor: AppColors.primary,
                  ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.calendar_today,
                      isNoExpiry ? 'Không thời hạn' : 'HSD: $endDateStr',
                      isExpired ? AppColors.error : Colors.grey[600]!,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      Icons.inventory_2,
                      '$usedCount/$quantity đã dùng',
                      usedCount >= quantity ? AppColors.error : Colors.grey[600]!,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (minOrder > 0)
                      _buildInfoChip(
                        Icons.shopping_cart,
                        'Tối thiểu: ${_formatMoney(minOrder)}',
                        Colors.grey[600]!,
                      ),
                    if (maxDiscount != null && discountType == 'percent') ...[
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        Icons.remove_circle_outline,
                        'Max: ${_formatMoney(maxDiscount)}',
                        Colors.grey[600]!,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Actions
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _showAddEditVoucherDialog(voucher: voucher),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Sửa'),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[200],
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _deleteVoucher(voucher),
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    label: const Text('Xóa', style: TextStyle(color: AppColors.error)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  List<Color> _getGradientColors(String type) {
    switch (type) {
      case 'shipping':
        return [const Color(0xFF3498db), const Color(0xFF2980b9)];
      case 'discount':
        return [const Color(0xFFe67e22), const Color(0xFFd35400)];
      default:
        return [AppColors.primary, AppColors.primaryDark];
    }
  }

  String _formatMoney(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return '${value.toInt()}đ';
  }
}

class _VoucherFormSheet extends StatefulWidget {
  final Map<String, dynamic>? voucher;
  final VoidCallback onSaved;

  const _VoucherFormSheet({
    this.voucher,
    required this.onSaved,
  });

  @override
  State<_VoucherFormSheet> createState() => _VoucherFormSheetState();
}

class _VoucherFormSheetState extends State<_VoucherFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final VoucherDao _voucherDao = VoucherDao();
  
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _discountValueController;
  late TextEditingController _minOrderController;
  late TextEditingController _maxDiscountController;
  late TextEditingController _quantityController;
  
  String _voucherType = 'discount'; // 'discount' hoặc 'shipping'
  String _discountType = 'percent'; // 'percent' hoặc 'fixed'
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isNoExpiry = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final v = widget.voucher;
    _codeController = TextEditingController(text: v?[VoucherContract.colCode] ?? '');
    _nameController = TextEditingController(text: v?[VoucherContract.colName] ?? '');
    _descriptionController = TextEditingController(text: v?[VoucherContract.colDescription] ?? '');
    _discountValueController = TextEditingController(
      text: (v?[VoucherContract.colDiscountValue] as num?)?.toString() ?? '10',
    );
    _minOrderController = TextEditingController(
      text: (v?[VoucherContract.colMinOrderValue] as num?)?.toString() ?? '0',
    );
    _maxDiscountController = TextEditingController(
      text: (v?[VoucherContract.colMaxDiscount] as num?)?.toString() ?? '',
    );
    _quantityController = TextEditingController(
      text: (v?[VoucherContract.colQuantity] as int?)?.toString() ?? '100',
    );
    
    if (v != null) {
      _voucherType = v[VoucherContract.colVoucherType] ?? 'discount';
      _discountType = v[VoucherContract.colDiscountType] ?? 'percent';
      _startDate = DateTime.fromMillisecondsSinceEpoch(
        v[VoucherContract.colStartDate] as int? ?? DateTime.now().millisecondsSinceEpoch,
      );
      final endDateValue = v[VoucherContract.colEndDate] as int?;
      _endDate = endDateValue != null 
          ? DateTime.fromMillisecondsSinceEpoch(endDateValue) 
          : null;
      _isNoExpiry = endDateValue == null;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _minOrderController.dispose();
    _maxDiscountController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Nếu endDate nhỏ hơn startDate, reset endDate
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      // Sửa lỗi: firstDate phải lớn hơn hoặc bằng startDate
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _saveVoucher() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final voucherData = {
        VoucherContract.colId: widget.voucher?[VoucherContract.colId] ?? 'vch_${DateTime.now().millisecondsSinceEpoch}',
        VoucherContract.colCode: _codeController.text.toUpperCase().trim(),
        VoucherContract.colName: _nameController.text.trim(),
        VoucherContract.colDescription: _descriptionController.text.trim(),
        VoucherContract.colVoucherType: _voucherType,
        VoucherContract.colDiscountType: _voucherType == 'shipping' ? 'fixed' : _discountType,
        VoucherContract.colDiscountValue: _voucherType == 'shipping' 
            ? 30000.0 
            : double.tryParse(_discountValueController.text) ?? 0,
        VoucherContract.colMinOrderValue: double.tryParse(_minOrderController.text) ?? 0,
        VoucherContract.colMaxDiscount: _voucherType == 'shipping' || _discountType != 'percent'
            ? null
            : (_maxDiscountController.text.isNotEmpty ? double.tryParse(_maxDiscountController.text) : null),
        VoucherContract.colQuantity: int.tryParse(_quantityController.text) ?? 100,
        VoucherContract.colStartDate: _startDate.millisecondsSinceEpoch,
        VoucherContract.colEndDate: _isNoExpiry ? null : _endDate?.millisecondsSinceEpoch,
        VoucherContract.colStatus: 'ACTIVE',
      };
      
      await _voucherDao.insertVoucher(voucherData);
      widget.onSaved();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.voucher == null ? 'Đã tạo voucher' : 'Đã cập nhật voucher'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.voucher == null ? 'Tạo Voucher Mới' : 'Chỉnh sửa Voucher',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              
              // Loại voucher - Dropdown
              DropdownButtonFormField<String>(
                value: _voucherType,
                decoration: const InputDecoration(
                  labelText: 'Loại Voucher',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'discount',
                    child: Row(
                      children: [
                        Icon(Icons.percent, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text('Giảm giá sản phẩm'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'shipping',
                    child: Row(
                      children: [
                        Icon(Icons.local_shipping, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text('Miễn phí vận chuyển'),
                      ],
                    ),
                  ),
                ],
                onChanged: (v) => setState(() {
                  _voucherType = v ?? 'discount';
                  if (_voucherType == 'shipping') {
                    _discountType = 'fixed';
                  }
                }),
              ),
              const SizedBox(height: 16),
              
              // Code
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Mã voucher',
                  hintText: 'VD: SUMMER2026',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_offer),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 16),
              
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên voucher',
                  hintText: 'VD: Giảm 10% mùa hè',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 16),
              
              // Discount type (chỉ hiện khi là discount)
              if (_voucherType == 'discount') ...[
                DropdownButtonFormField<String>(
                  value: _discountType,
                  decoration: const InputDecoration(
                    labelText: 'Loại giảm giá',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.percent),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'percent', child: Text('Phần trăm (%)')),
                    DropdownMenuItem(value: 'fixed', child: Text('Số tiền cố định (VNĐ)')),
                  ],
                  onChanged: (v) => setState(() => _discountType = v ?? 'percent'),
                ),
                const SizedBox(height: 16),
              ],
              
              // Discount value (chỉ hiện khi là discount)
              if (_voucherType == 'discount') ...[
                TextFormField(
                  controller: _discountValueController,
                  decoration: InputDecoration(
                    labelText: _discountType == 'percent' ? 'Phần trăm giảm (%)' : 'Số tiền giảm (VNĐ)',
                    hintText: _discountType == 'percent' ? 'VD: 10' : 'VD: 50000',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.discount),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
                ),
                const SizedBox(height: 16),
              ],
              
              // Min order
              TextFormField(
                controller: _minOrderController,
                decoration: const InputDecoration(
                  labelText: 'Đơn hàng tối thiểu (VNĐ)',
                  hintText: 'VD: 200000',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_cart),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              // Max discount (chỉ cho percent)
              if (_voucherType == 'discount' && _discountType == 'percent') ...[
                TextFormField(
                  controller: _maxDiscountController,
                  decoration: const InputDecoration(
                    labelText: 'Giảm tối đa (VNĐ)',
                    hintText: 'VD: 50000',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.remove_circle_outline),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
              ],
              
              // Quantity
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Số lượng phát hành',
                  hintText: 'VD: 100',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 16),
              
              // Date range
              Text(
                'Thời hạn',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              
              // Checkbox không thời hạn
              CheckboxListTile(
                value: _isNoExpiry,
                onChanged: (v) => setState(() {
                  _isNoExpiry = v ?? false;
                  if (_isNoExpiry) _endDate = null;
                }),
                title: const Text('Không giới hạn thời gian'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              
              // Date pickers
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectStartDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngày bắt đầu',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event),
                        ),
                        child: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                      ),
                    ),
                  ),
                  if (!_isNoExpiry) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: _selectEndDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Ngày kết thúc',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.event),
                          ),
                          child: Text(
                            _endDate != null 
                                ? DateFormat('dd/MM/yyyy').format(_endDate!)
                                : 'Chọn ngày',
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveVoucher,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(widget.voucher == null ? 'TẠO MỚI' : 'LƯU'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
