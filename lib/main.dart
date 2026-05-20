import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'routes/app_routes.dart';
import 'utils/constants/route_names.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'database/daos/user_dao.dart';
import 'database/daos/address_dao.dart';
import 'database/daos/product_dao.dart';
import 'database/daos/category_dao.dart';
import 'database/daos/cart_dao.dart';
import 'database/daos/order_dao.dart';
import 'database/daos/recently_viewed_dao.dart';
import 'database/daos/favorite_dao.dart';
import 'database/daos/voucher_dao.dart';
import 'database/daos/review_dao.dart';
import 'database/repositories/voucher_repository.dart';

import 'database/repositories/auth_repository.dart';
import 'database/repositories/user_repository.dart';
import 'database/repositories/product_repository.dart';
import 'database/repositories/cart_repository.dart';
import 'database/repositories/order_repository.dart';

import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/recently_viewed_provider.dart';
import 'providers/favorite_provider.dart';
import 'providers/search_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/review_provider.dart';
import 'providers/voucher_provider.dart';

import 'widgets/common/loading_screen.dart';

class _AppInitializationResult {
  final AuthProvider authProvider;
  final UserProvider userProvider;
  final ProductProvider productProvider;
  final CartProvider cartProvider;
  final OrderProvider orderProvider;
  final RecentlyViewedProvider recentlyViewedProvider;
  final FavoriteProvider favoriteProvider;
  final SearchProvider searchProvider;
  final ReviewProvider reviewProvider;
  final VoucherProvider voucherProvider;

  _AppInitializationResult({
    required this.authProvider,
    required this.userProvider,
    required this.productProvider,
    required this.cartProvider,
    required this.orderProvider,
    required this.recentlyViewedProvider,
    required this.favoriteProvider,
    required this.searchProvider,
    required this.reviewProvider,
    required this.voucherProvider,
  });
}

Future<_AppInitializationResult> _initializeApp() async {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final userDao = UserDao();
  final addressDao = AddressDao();
  final productDao = ProductDao();
  final categoryDao = CategoryDao();
  final cartDao = CartDao();
  final orderDao = OrderDao();
  final recentlyViewedDao = RecentlyViewedDao();
  final favoriteDao = FavoriteDao();
  final reviewDao = ReviewDao();
  final voucherDao = VoucherDao();

  final authRepo = AuthRepository(userDao: userDao);
  final userRepo = UserRepository(userDao: userDao, addressDao: addressDao);
  final productRepo = ProductRepository(productDao: productDao, categoryDao: categoryDao);
  final cartRepo = CartRepository(cartDao: cartDao);
  final orderRepo = OrderRepository(orderDao: orderDao);
  final voucherRepo = VoucherRepository(voucherDao: voucherDao);

  final authProvider = AuthProvider(authRepository: authRepo);
  await authProvider.tryAutoLogin();

  return _AppInitializationResult(
    authProvider: authProvider,
    userProvider: UserProvider(userRepository: userRepo),
    productProvider: ProductProvider(productRepository: productRepo),
    cartProvider: CartProvider(cartRepository: cartRepo),
    orderProvider: OrderProvider(orderRepository: orderRepo),
    recentlyViewedProvider: RecentlyViewedProvider(recentlyViewedDao: recentlyViewedDao),
    favoriteProvider: FavoriteProvider(favoriteDao: favoriteDao),
    searchProvider: SearchProvider(productRepository: productRepo),
    reviewProvider: ReviewProvider(reviewDao: reviewDao),
    voucherProvider: VoucherProvider(voucherRepository: voucherRepo),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final initFuture = _initializeApp();

  runApp(_InitializingApp(initFuture: initFuture));
}

class _InitializingApp extends StatelessWidget {
  final Future<_AppInitializationResult> initFuture;

  const _InitializingApp({required this.initFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AppInitializationResult>(
      future: initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingScreen();
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Text('Lỗi khởi tạo: ${snapshot.error}'),
            ),
          );
        }

        final result = snapshot.data!;

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider.value(value: result.authProvider),
            ChangeNotifierProvider.value(value: result.userProvider),
            ChangeNotifierProvider.value(value: result.productProvider),
            ChangeNotifierProvider.value(value: result.cartProvider),
            ChangeNotifierProvider.value(value: result.orderProvider),
            ChangeNotifierProvider.value(value: result.recentlyViewedProvider),
            ChangeNotifierProvider.value(value: result.favoriteProvider),
            ChangeNotifierProvider.value(value: result.searchProvider),
            ChangeNotifierProvider.value(value: result.reviewProvider),
            ChangeNotifierProvider.value(value: result.voucherProvider),
          ],
          child: const MyApp(),
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'Cửa Hàng Hoa Sen Đá',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: auth.isAuthenticated ? RouteNames.home : RouteNames.login,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
