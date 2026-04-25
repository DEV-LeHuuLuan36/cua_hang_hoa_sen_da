import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/search_provider.dart';
import '../../../providers/recently_viewed_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/constants/route_names.dart';
import '../../../widgets/common/product_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Hàm hiển thị BottomSheet Bộ Lọc
  void _showFilterSheet(BuildContext context) {
    final searchProvider = context.read<SearchProvider>();
    double? tempMinPrice = searchProvider.minPrice;
    double? tempMaxPrice = searchProvider.maxPrice;
    String? tempCareLevel = searchProvider.careLevel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bộ lọc tìm kiếm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Lọc theo Khoảng giá
                  const Text('Khoảng giá (VNĐ)', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: 'Tối thiểu'),
                          onChanged: (val) => tempMinPrice = double.tryParse(val),
                        ),
                      ),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('-')),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: 'Tối đa'),
                          onChanged: (val) => tempMaxPrice = double.tryParse(val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Lọc theo Độ khó chăm sóc
                  const Text('Độ khó chăm sóc', style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: ['EASY', 'MEDIUM', 'HARD'].map((level) {
                      final isSelected = tempCareLevel == level;
                      return ChoiceChip(
                        label: Text(level == 'EASY' ? 'Dễ' : level == 'MEDIUM' ? 'Trung bình' : 'Khó'),
                        selected: isSelected,
                        selectedColor: AppColors.primaryLight,
                        onSelected: (selected) {
                          setState(() {
                            tempCareLevel = selected ? level : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Các nút hành động
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            searchProvider.clearFilter();
                            Navigator.pop(ctx);
                          },
                          child: const Text('XÓA BỘ LỌC'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          onPressed: () {
                            searchProvider.applyFilter(
                              minPrice: tempMinPrice,
                              maxPrice: tempMaxPrice,
                              careLevel: tempCareLevel,
                            );
                            Navigator.pop(ctx);
                          },
                          child: const Text('ÁP DỤNG', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Tìm kiếm sen đá...',
            border: InputBorder.none,
          ),
          onSubmitted: (value) {
            context.read<SearchProvider>().searchProducts(value);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.primary),
            onPressed: () => _showFilterSheet(context),
          )
        ],
      ),
      body: Consumer<SearchProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final results = provider.searchResults;

          if (results.isEmpty && _searchController.text.isNotEmpty) {
            return const Center(child: Text('Không tìm thấy sản phẩm nào!'));
          }

          return GridView.builder(
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
          );
        },
      ),
    );
  }
}