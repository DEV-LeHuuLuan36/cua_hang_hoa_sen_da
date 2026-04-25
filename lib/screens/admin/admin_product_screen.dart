import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/product/succulent.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants/route_names.dart';
import '../../widgets/common/pressable_scale.dart';
import '../../widgets/common/shimmer_box.dart';

class AdminProductScreen extends StatefulWidget {
  const AdminProductScreen({Key? key}) : super(key: key);

  @override
  State<AdminProductScreen> createState() => _AdminProductScreenState();
}

class _AdminProductScreenState extends State<AdminProductScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductProvider>();
      provider.loadCategories();
      provider.loadAllProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<ProductProvider>().searchProducts(query);
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<ProductProvider>().searchProducts('');
  }

  void _onCategorySelected(String? categoryId) {
    HapticFeedback.selectionClick();
    context.read<ProductProvider>().setCategoryFilter(categoryId);
  }

  void _clearAllFilters() {
    HapticFeedback.lightImpact();
    _searchController.clear();
    context.read<ProductProvider>().clearFilters();
  }

  Future<void> _showQuickUpdateDialog(Succulent product) async {
    final priceController = TextEditingController(text: product.price.toStringAsFixed(0));
    final stockController = TextEditingController(text: product.stock.toString());

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sửa nhanh giá và tồn kho'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Giá (VNĐ)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Tồn kho'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (shouldSave != true) return;
    final newPrice = double.tryParse(priceController.text.trim());
    final newStock = int.tryParse(stockController.text.trim());
    if (newPrice == null || newStock == null) return;

    final updated = Succulent(
      id: product.id,
      categoryId: product.categoryId,
      name: product.name,
      scientificName: product.scientificName,
      description: product.description,
      price: newPrice,
      salePrice: product.salePrice,
      stock: newStock,
      sku: product.sku,
      status: product.status,
      size: product.size,
      color: product.color,
      origin: product.origin,
      careInstruction: product.careInstruction,
      isBestseller: product.isBestseller,
      isNew: product.isNew,
      rating: product.rating,
      reviewCount: product.reviewCount,
      views: product.views,
      createdAt: product.createdAt,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    final ok = await context.read<ProductProvider>().updateProduct(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Cập nhật sản phẩm thành công!' : 'Cập nhật sản phẩm thất bại!'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _deleteProduct(String productId) async {
    HapticFeedback.lightImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: const Text('Bạn có chắc chắn muốn xóa sản phẩm này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    final ok = await context.read<ProductProvider>().deleteProduct(productId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Xóa sản phẩm thành công!' : 'Xóa sản phẩm thất bại!'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final products = productProvider.products;
    final categories = productProvider.categories;
    final selectedCategoryId = productProvider.selectedCategoryId;
    final hasActiveFilter = productProvider.searchQuery.isNotEmpty || selectedCategoryId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản lý Sản phẩm', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryDark,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // ─── Thanh Search ───
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: AppColors.surface,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7)),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // ─── Filter Chips danh mục ───
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Chip "Tất cả"
                      _CategoryChip(
                        label: 'Tất cả',
                        isSelected: selectedCategoryId == null,
                        onTap: () => _onCategorySelected(null),
                      ),
                      const SizedBox(width: 8),
                      // Chips danh mục từ DB
                      ...categories.map((cat) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _CategoryChip(
                              label: cat.name,
                              isSelected: selectedCategoryId == cat.id,
                              onTap: () => _onCategorySelected(cat.id),
                            ),
                          )),
                    ],
                  ),
                ),
                if (hasActiveFilter) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _clearAllFilters,
                    child: Row(
                      children: [
                        const Icon(Icons.filter_alt_off, size: 14, color: AppColors.error),
                        const SizedBox(width: 4),
                        Text(
                          'Xóa bộ lọc',
                          style: TextStyle(fontSize: 12, color: AppColors.error.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ─── Divider ───
          Container(height: 1, color: AppColors.background),

          // ─── Danh sách sản phẩm ───
          Expanded(
            child: productProvider.isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 6,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: ShimmerBox(width: double.infinity, height: 90, borderRadius: 12),
                    ),
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.fastOutSlowIn,
                    switchOutCurve: Curves.fastOutSlowIn,
                    child: products.isEmpty
                        ? _EmptyState(hasFilter: hasActiveFilter)
                        : ListView.builder(
                            key: ValueKey(products.length),
                            padding: const EdgeInsets.all(16),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final p = products[index];
                              return _ProductTile(
                                key: ValueKey(p.id),
                                product: p,
                                onQuickEdit: () => _showQuickUpdateDialog(p),
                                onEdit: () => Navigator.pushNamed(
                                  context,
                                  RouteNames.adminAddEditProduct,
                                  arguments: p.id,
                                ),
                                onDelete: () => _deleteProduct(p.id),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryDark,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm SP', style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.pushNamed(context, RouteNames.adminAddEditProduct);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Widget con: Chip danh mục
// ─────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      pressedScale: 0.93,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Widget con: Dòng sản phẩm
// ─────────────────────────────────────────────
class _ProductTile extends StatelessWidget {
  final Succulent product;
  final VoidCallback onQuickEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductTile({
    required super.key,
    required this.product,
    required this.onQuickEdit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.eco, color: AppColors.primary),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Giá: ${product.price.toInt()} VNĐ  |  Kho: ${product.stock}',
          style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.85)),
        ),
        trailing: PressableScale(
          pressedScale: 0.92,
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onSelected: (value) {
              if (value == 'quick') {
                onQuickEdit();
              } else if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'quick', child: Text('Sửa nhanh giá/tồn')),
              const PopupMenuItem(value: 'edit', child: Text('Mở form chỉnh sửa')),
              PopupMenuItem(
                value: 'delete',
                child: Text('Xóa sản phẩm', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Widget con: Empty state
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasFilter;

  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('empty'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilter ? Icons.search_off_rounded : Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'Không tìm thấy sản phẩm nào!' : 'Chưa có sản phẩm nào.\nHãy bấm dấu + để thêm.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, height: 1.5),
          ),
        ],
      ),
    );
  }
}
