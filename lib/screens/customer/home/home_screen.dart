import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/constants/route_names.dart';
import '../../../widgets/common/product_card.dart';
import '../../../widgets/common/shimmer_box.dart';
import '../../../providers/product_provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/theme_helper.dart';
import '../../../screens/admin/admin_dashboard_screen.dart';
import '../cart/cart_screen.dart';
import '../profile/profile_screen.dart';

import '../../../providers/recently_viewed_provider.dart';

// ============================================================
// AuthGate — root widget for /home, decides route by role
// ============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _redirected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuth());
  }

  void _checkAuth() {
    if (!mounted || _redirected) return;
    final auth = context.read<AuthProvider>();

    if (!auth.isAuthenticated) {
      _redirected = true;
      Navigator.pushReplacementNamed(context, RouteNames.login);
      return;
    }

    if (auth.isAdmin) {
      _redirected = true;
      Navigator.pushReplacementNamed(context, RouteNames.adminDashboard);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading || !auth.isAuthenticated) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (auth.isAdmin) {
      return const AdminDashboardScreen();
    }

    return const CustomerShell();
  }
}

// ============================================================
// CustomerShell — bottom-nav shell for regular customers
// ============================================================
class CustomerShell extends StatefulWidget {
  const CustomerShell({Key? key}) : super(key: key);

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const CustomerContent(),
    const CartScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeHelper.background(context),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: ThemeHelper.icon(context),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Giỏ hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CustomerContent — product grid on the home tab
// ============================================================
class CustomerContent extends StatefulWidget {
  const CustomerContent({Key? key}) : super(key: key);

  @override
  State<CustomerContent> createState() => _CustomerContentState();
}

class _CustomerContentState extends State<CustomerContent> {
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
    final user = context.watch<AuthProvider>().currentUser;
    final displayName = user?.fullName ?? 'Khách hàng';

    final productProvider = context.watch<ProductProvider>();
    final products = productProvider.products;
    final isLoading = productProvider.isLoading;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chào buổi sáng,',
                      style: TextStyle(fontSize: 14, color: ThemeHelper.textSecondary(context)),
                    ),
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.primary : AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, RouteNames.myVouchers),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ThemeHelper.surface(context),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                        ),
                        child: Icon(
                          Icons.local_offer_outlined,
                          color: isDark ? AppColors.primary : AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, RouteNames.notifications),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ThemeHelper.surface(context),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                        ),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: isDark ? AppColors.primary : AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryLight, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Khuyến mãi mùa hè!', style: TextStyle(color: Colors.white, fontSize: 16)),
                    SizedBox(height: 8),
                    Text(
                      'Giảm giá 30%\ntất cả các loại\nSen Đá Echeveria',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Sản phẩm mới nhất',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThemeHelper.textPrimary(context)),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              SizedBox(
                height: 480,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) => const ShimmerGridItem(),
                ),
              )
            else if (products.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: ThemeHelper.textSecondary(context)),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có sản phẩm nào trong cửa hàng.\nVui lòng vào mục Quản trị (Admin) để thêm SP.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: ThemeHelper.textSecondary(context), height: 1.5),
                      ),
                    ],
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.fastOutSlowIn,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: ThemeHelper.textPrimary(context).withValues(alpha: 0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ProductCard(
                      product: product,
                      enablePressScale: true,
                      onTap: () {
                        final userId = context.read<AuthProvider>().currentUser?.id;

                        if (userId != null) {
                          context.read<RecentlyViewedProvider>().addViewedProduct(userId, product.id);
                        }

                        Navigator.pushNamed(
                          context,
                          RouteNames.productDetail,
                          arguments: product.id,
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
