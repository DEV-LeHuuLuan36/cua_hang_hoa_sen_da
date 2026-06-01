import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/theme_helper.dart';
import '../../../providers/recently_viewed_provider.dart';
import '../../../widgets/common/shimmer_box.dart';
import '../../../providers/auth_provider.dart';

class RecentlyViewedScreen extends StatefulWidget {
  const RecentlyViewedScreen({Key? key}) : super(key: key);

  @override
  State<RecentlyViewedScreen> createState() => _RecentlyViewedScreenState();
}

class _RecentlyViewedScreenState extends State<RecentlyViewedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<RecentlyViewedProvider>().loadRecentlyViewed(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: ThemeHelper.background(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Đã xem gần đây',
          style: TextStyle(color: ThemeHelper.textPrimary(context)),
        ),
        backgroundColor: ThemeHelper.surface(context),
        elevation: 0,
        iconTheme: IconThemeData(color: ThemeHelper.textPrimary(context)),
      ),
      body: Consumer<RecentlyViewedProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 4,
              itemBuilder: (context, index) => const ShimmerGridItem(),
            );
          }

          final products = provider.viewedProducts;

          if (products.isEmpty) {
            return Center(
              child: Text(
                'Bạn chưa xem sản phẩm nào!',
                style: TextStyle(color: ThemeHelper.textSecondary(context), fontSize: 16),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Container(
                decoration: BoxDecoration(
                  color: ThemeHelper.surface(context),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: product['primary_image'] != null && (product['primary_image'] as String).isNotEmpty
                            ? Image.asset(
                                product['primary_image'] as String,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildPlaceholder(),
                              )
                            : _buildPlaceholder(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'] ?? 'Sản phẩm',
                            style: TextStyle(fontWeight: FontWeight.bold, color: ThemeHelper.textPrimary(context)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${product['price']}đ',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.primaryLight.withValues(alpha: 0.2),
      child: Center(
        child: Icon(Icons.eco, size: 50, color: AppColors.primary),
      ),
    );
  }
}
