import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/search_provider.dart';
import '../../../providers/recently_viewed_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/constants/route_names.dart';
import '../../../widgets/common/product_card.dart';
import '../../../widgets/common/shimmer_box.dart';
import '../../../widgets/filter/filter_bottom_sheet.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Tải danh mục khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasFilters = searchProvider.hasActiveFilters;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm sen đá...',
            hintStyle: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : Colors.grey,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onSubmitted: (value) {
            searchProvider.searchProducts(value);
          },
        ),
        actions: [
          // Nút xóa text tìm kiếm
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: isDark ? AppColors.darkTextSecondary : Colors.grey),
              onPressed: () {
                _searchController.clear();
                searchProvider.searchProducts('');
              },
            ),
          // Nút bộ lọc
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.tune,
                  color: hasFilters ? AppColors.primary : (isDark ? AppColors.darkIcon : AppColors.primary),
                ),
                onPressed: () => _showFilterSheet(context),
              ),
              if (hasFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Consumer<SearchProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 6,
                itemBuilder: (context, index) => const ShimmerGridItem(),
              ),
            );
          }

          final results = provider.searchResults;

          // Trạng thái trống - chưa tìm kiếm
          if (_searchController.text.isEmpty && results.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search,
                    size: 80,
                    color: isDark ? AppColors.darkBorder : Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tìm kiếm sản phẩm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nhập tên sản phẩm bạn muốn tìm',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          // Không có kết quả
          if (results.isEmpty && _searchController.text.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 80,
                    color: isDark ? AppColors.darkBorder : Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không tìm thấy sản phẩm nào!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thử từ khóa khác hoặc điều chỉnh bộ lọc',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () {
                      searchProvider.resetFilter();
                      _searchController.clear();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Xóa bộ lọc'),
                  ),
                ],
              ),
            );
          }

          // Hiển thị kết quả
          return Column(
            children: [
              // Thanh thông tin kết quả
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isDark ? AppColors.darkSurface : Colors.grey[100],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tìm thấy ${results.length} sản phẩm',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    if (hasFilters)
                      TextButton(
                        onPressed: () {
                          searchProvider.resetFilter();
                        },
                        child: const Text('Xóa lọc'),
                      ),
                  ],
                ),
              ),
              // Grid sản phẩm
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final product = results[index];
                    return ProductCard(
                      product: product,
                      enablePressScale: true,
                      onTap: () {
                        final userId = context.read<AuthProvider>().currentUser?.id;
                        if (userId != null) {
                          context.read<RecentlyViewedProvider>().addViewedProduct(userId, product.id);
                        }
                        Navigator.pushNamed(context, RouteNames.productDetail, arguments: product.id);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
