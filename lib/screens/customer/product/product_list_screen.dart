import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/product_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/theme_helper.dart';
import '../../../utils/constants/route_names.dart';
import '../../../widgets/common/product_card.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadAllProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productProvider = context.watch<ProductProvider>();
    final products = productProvider.products;

    return Scaffold(
      backgroundColor: ThemeHelper.background(context),
      appBar: AppBar(
        title: Text(
          'Sen đá Echeveria',
          style: TextStyle(color: ThemeHelper.textPrimary(context), fontWeight: FontWeight.bold),
        ),
        backgroundColor: ThemeHelper.surface(context),
        elevation: 0,
        iconTheme: IconThemeData(color: ThemeHelper.textPrimary(context)),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: ThemeHelper.icon(context)),
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart_outlined, color: ThemeHelper.icon(context)),
            onPressed: () {
              Navigator.pushNamed(context, RouteNames.cart);
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            color: ThemeHelper.surface(context),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ThemeHelper.textPrimary(context),
                    side: BorderSide(color: isDark ? AppColors.darkBorder : Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.filter_list, size: 18),
                  label: const Text('Lọc'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ThemeHelper.textPrimary(context),
                    side: BorderSide(color: isDark ? AppColors.darkBorder : Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.sort, size: 18),
                  label: const Text('Bán chạy nhất'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: productProvider.isLoading
                ? Center(child: CircularProgressIndicator(color: isDark ? AppColors.primary : AppColors.primary))
                : GridView.builder(
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
                      return ProductCard(
                        product: product,
                        enablePressScale: true,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            RouteNames.productDetail,
                            arguments: product.id,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
