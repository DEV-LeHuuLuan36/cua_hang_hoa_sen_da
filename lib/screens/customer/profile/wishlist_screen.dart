import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/theme_helper.dart';
import '../../../providers/favorite_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/product_card.dart';
import '../../../widgets/common/shimmer_box.dart';
import '../../../widgets/common/empty_state_widget.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({Key? key}) : super(key: key);

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<FavoriteProvider>().fetchFavorites(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: ThemeHelper.background(context),
      appBar: AppBar(
        title: Text(
          'Sản phẩm yêu thích',
          style: TextStyle(color: ThemeHelper.textPrimary(context), fontWeight: FontWeight.bold),
        ),
        backgroundColor: ThemeHelper.surface(context),
        elevation: 0.5,
        iconTheme: IconThemeData(color: ThemeHelper.textPrimary(context)),
      ),
      body: Consumer<FavoriteProvider>(
        builder: (context, favProvider, child) {
          if (favProvider.isLoading) {
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

          if (favProvider.favoriteProducts.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.favorite_border,
              message: 'Bạn chưa yêu thích sản phẩm nào',
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
            itemCount: favProvider.favoriteProducts.length,
            itemBuilder: (context, index) {
              final product = favProvider.favoriteProducts[index];
              return ProductCard(
                product: product,
                enablePressScale: true,
              );
            },
          );
        },
      ),
    );
  }
}
