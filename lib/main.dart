import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'routes/app_routes.dart';
import 'utils/constants/route_names.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

// 1. Import DAOs
import 'database/daos/user_dao.dart';
import 'database/daos/address_dao.dart';
import 'database/daos/product_dao.dart';
import 'database/daos/category_dao.dart';
import 'database/daos/cart_dao.dart';
import 'database/daos/order_dao.dart';
import 'database/daos/recently_viewed_dao.dart';
import 'database/daos/favorite_dao.dart';
import 'database/daos/review_dao.dart';

// 2. Import Repositories
import 'database/repositories/auth_repository.dart';
import 'database/repositories/user_repository.dart';
import 'database/repositories/product_repository.dart';
import 'database/repositories/cart_repository.dart';
import 'database/repositories/order_repository.dart';

// 3. Import Providers
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // KHỞI TẠO DAOs
  final userDao = UserDao();
  final addressDao = AddressDao();
  final productDao = ProductDao();
  final categoryDao = CategoryDao();
  final cartDao = CartDao();
  final orderDao = OrderDao();
  final recentlyViewedDao = RecentlyViewedDao();
  final favoriteDao = FavoriteDao();
  final reviewDao = ReviewDao();

  // KHỞI TẠO REPOSITORIES
  final authRepo = AuthRepository(userDao: userDao);
  final userRepo = UserRepository(userDao: userDao, addressDao: addressDao);
  final productRepo = ProductRepository(productDao: productDao, categoryDao: categoryDao);
  final cartRepo = CartRepository(cartDao: cartDao);
  final orderRepo = OrderRepository(orderDao: orderDao);

  // Khởi tạo AuthProvider trước để check trạng thái đăng nhập
  final authProvider = AuthProvider(authRepository: authRepo);
  await authProvider.tryAutoLogin();

  // CHẠY APP VỚI ĐẦY ĐỦ CÁC PROVIDER
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => UserProvider(userRepository: userRepo)),
        ChangeNotifierProvider(create: (_) => ProductProvider(productRepository: productRepo)),
        ChangeNotifierProvider(create: (_) => CartProvider(cartRepository: cartRepo)),
        ChangeNotifierProvider(create: (_) => OrderProvider(orderRepository: orderRepo)),
        ChangeNotifierProvider(create: (_) => RecentlyViewedProvider(recentlyViewedDao: recentlyViewedDao)),
        ChangeNotifierProvider(create: (_) => FavoriteProvider(favoriteDao: favoriteDao)),
        ChangeNotifierProvider(create: (_) => SearchProvider(productRepository: productRepo)),
        ChangeNotifierProvider(create: (_) => ReviewProvider(reviewDao: reviewDao)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context);

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
