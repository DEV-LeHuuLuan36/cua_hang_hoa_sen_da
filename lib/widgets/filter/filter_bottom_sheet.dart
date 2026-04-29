import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/enums/product_status.dart';
import '../../models/product/category.dart';
import '../../providers/search_provider.dart';
import '../../theme/app_colors.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late RangeValues _currentPriceRange;
  String? _selectedCategoryId;
  ProductStatus? _selectedStatus;
  String? _selectedCareLevel;
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    final searchProvider = context.read<SearchProvider>();
    _currentPriceRange = searchProvider.priceRange;
    _selectedCategoryId = searchProvider.selectedCategoryId;
    _selectedStatus = searchProvider.selectedStatus;
    _selectedCareLevel = searchProvider.selectedCareLevel;
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();
    final categories = searchProvider.categories;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBorder : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lọc Sản Phẩm',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: isDark ? AppColors.darkTextSecondary : Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ===== Mục 1: Khoảng giá =====
                  _buildSectionTitle('Khoảng giá (VNĐ)', isDark),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _currencyFormat.format(_currentPriceRange.start),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(_currentPriceRange.end),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _currentPriceRange,
                    min: 0,
                    max: 500000,
                    divisions: 50,
                    activeColor: AppColors.primary,
                    inactiveColor: isDark ? AppColors.darkBorder : Colors.grey[300],
                    labels: RangeLabels(
                      _currencyFormat.format(_currentPriceRange.start),
                      _currencyFormat.format(_currentPriceRange.end),
                    ),
                    onChanged: (values) {
                      setSheetState(() {
                        _currentPriceRange = values;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // ===== Mục 2: Danh mục =====
                  _buildSectionTitle('Danh mục', isDark),
                  const SizedBox(height: 8),
                  if (categories.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Đang tải danh mục...',
                        style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...categories.map((category) {
                          return ChoiceChip(
                            label: Text(category.name),
                            selected: _selectedCategoryId == category.id,
                            selectedColor: AppColors.primaryLight,
                            labelStyle: TextStyle(
                              color: _selectedCategoryId == category.id
                                  ? Colors.white
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                            ),
                            onSelected: (selected) {
                              setSheetState(() {
                                _selectedCategoryId = selected ? category.id : null;
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  const SizedBox(height: 24),

                  // ===== Mục 3: Trạng thái =====
                  _buildSectionTitle('Trạng thái', isDark),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Còn hàng'),
                        selected: _selectedStatus == ProductStatus.AVAILABLE,
                        selectedColor: AppColors.primaryLight,
                        labelStyle: TextStyle(
                          color: _selectedStatus == ProductStatus.AVAILABLE
                              ? Colors.white
                              : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                        ),
                        onSelected: (selected) {
                          setSheetState(() {
                            _selectedStatus = selected ? ProductStatus.AVAILABLE : null;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Hết hàng'),
                        selected: _selectedStatus == ProductStatus.OUT_OF_STOCK,
                        selectedColor: AppColors.primaryLight,
                        labelStyle: TextStyle(
                          color: _selectedStatus == ProductStatus.OUT_OF_STOCK
                              ? Colors.white
                              : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                        ),
                        onSelected: (selected) {
                          setSheetState(() {
                            _selectedStatus = selected ? ProductStatus.OUT_OF_STOCK : null;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Ẩn'),
                        selected: _selectedStatus == ProductStatus.HIDDEN,
                        selectedColor: AppColors.primaryLight,
                        labelStyle: TextStyle(
                          color: _selectedStatus == ProductStatus.HIDDEN
                              ? Colors.white
                              : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                        ),
                        onSelected: (selected) {
                          setSheetState(() {
                            _selectedStatus = selected ? ProductStatus.HIDDEN : null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ===== Mục 4: Độ khó chăm sóc =====
                  _buildSectionTitle('Độ khó chăm sóc', isDark),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Dễ'),
                        selected: _selectedCareLevel == 'EASY',
                        selectedColor: AppColors.primaryLight,
                        labelStyle: TextStyle(
                          color: _selectedCareLevel == 'EASY'
                              ? Colors.white
                              : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                        ),
                        onSelected: (selected) {
                          setSheetState(() {
                            _selectedCareLevel = selected ? 'EASY' : null;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Trung bình'),
                        selected: _selectedCareLevel == 'MEDIUM',
                        selectedColor: AppColors.primaryLight,
                        labelStyle: TextStyle(
                          color: _selectedCareLevel == 'MEDIUM'
                              ? Colors.white
                              : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                        ),
                        onSelected: (selected) {
                          setSheetState(() {
                            _selectedCareLevel = selected ? 'MEDIUM' : null;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Khó'),
                        selected: _selectedCareLevel == 'HARD',
                        selectedColor: AppColors.primaryLight,
                        labelStyle: TextStyle(
                          color: _selectedCareLevel == 'HARD'
                              ? Colors.white
                              : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                        ),
                        onSelected: (selected) {
                          setSheetState(() {
                            _selectedCareLevel = selected ? 'HARD' : null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ===== Nút hành động =====
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final provider = context.read<SearchProvider>();
                            setSheetState(() {
                              _currentPriceRange = const RangeValues(0, 500000);
                              _selectedCategoryId = null;
                              _selectedStatus = null;
                              _selectedCareLevel = null;
                            });
                            provider.resetFilter();
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: isDark ? AppColors.darkBorder : Colors.grey),
                          ),
                          child: Text(
                            'Thiết lập lại',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            final provider = context.read<SearchProvider>();
                            provider.applyFilter(
                              priceRange: _currentPriceRange,
                              categoryId: _selectedCategoryId,
                              status: _selectedStatus,
                              careLevel: _selectedCareLevel,
                            );
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Áp dụng',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
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
      },
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      ),
    );
  }
}
