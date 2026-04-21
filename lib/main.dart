import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'routes/app_routes.dart';
import 'utils/constants/route_names.dart';

// 1. Import DAOs
import 'database/daos/user_dao.dart';
import 'database/daos/address_dao.dart';
import 'database/daos/product_dao.dart';
import 'database/daos/category_dao.dart';
import 'database/daos/cart_dao.dart';
import 'database/daos/order_dao.dart';
import 'database/daos/recently_viewed_dao.dart';
import 'database/daos/favorite_dao.dart'; // <-- Bổ sung DAO yêu thích

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
import 'providers/favorite_provider.dart'; // <-- Bổ sung Provider yêu thích
import 'providers/search_provider.dart';

Future<void> main() async {
  // Đảm bảo Flutter binding được khởi tạo
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
  final favoriteDao = FavoriteDao(); // <-- Khởi tạo DAO yêu thích

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
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => UserProvider(userRepository: userRepo)),
        ChangeNotifierProvider(create: (_) => ProductProvider(productRepository: productRepo)),
        ChangeNotifierProvider(create: (_) => CartProvider(cartRepository: cartRepo)),
        ChangeNotifierProvider(create: (_) => OrderProvider(orderRepository: orderRepo)),
        ChangeNotifierProvider(create: (_) => RecentlyViewedProvider(recentlyViewedDao: recentlyViewedDao)),
        ChangeNotifierProvider(create: (_) => FavoriteProvider(favoriteDao: favoriteDao)), // <-- Khai báo hộ khẩu cho Favorite
        ChangeNotifierProvider(create: (_) => SearchProvider(productRepository: productRepo)),
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

    return MaterialApp(
      title: 'Cửa Hàng Hoa Sen Đá',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Plus Jakarta Sans',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      initialRoute: auth.isAuthenticated ? RouteNames.home : RouteNames.login,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}