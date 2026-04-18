import 'package:cua_hang_hoa_sen_da/routes/app_routes.dart';
import 'package:cua_hang_hoa_sen_da/utils/constants/route_names.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// 1. Import DAOs
import 'database/daos/recently_viewed_dao.dart';
import 'database/daos/user_dao.dart';
import 'database/daos/product_dao.dart';
import 'database/daos/category_dao.dart';
import 'database/daos/cart_dao.dart';
import 'database/daos/order_dao.dart';

// 2. Import Repositories
import 'database/repositories/auth_repository.dart';
import 'database/repositories/product_repository.dart';
import 'database/repositories/cart_repository.dart';
import 'database/repositories/order_repository.dart';

// 3. Import Providers
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/search_provider.dart';
import 'providers/recently_viewed_provider.dart';

Future<void> main() async {
  // Đảm bảo các widget binding của Flutter được khởi tạo trước khi gọi SQLite
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // BƯỚC 1: KHỞI TẠO DAOs
  final userDao = UserDao();
  final productDao = ProductDao();
  final categoryDao = CategoryDao();
  final cartDao = CartDao();
  final orderDao = OrderDao();
  final recentlyViewedDao = RecentlyViewedDao();

  // BƯỚC 2: KHỞI TẠO REPOSITORIES (Bơm DAO vào Repository)
  final authRepo = AuthRepository(userDao: userDao);
  final productRepo = ProductRepository(productDao: productDao, categoryDao: categoryDao);
  final cartRepo = CartRepository(cartDao: cartDao);
  final orderRepo = OrderRepository(orderDao: orderDao);
  final authProvider = AuthProvider(authRepository: authRepo);
  await authProvider.tryAutoLogin();
  // BƯỚC 3: CHẠY APP VỚI MULTIPROVIDER
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ProductProvider(productRepository: productRepo)),
        ChangeNotifierProvider(create: (_) => CartProvider(cartRepository: cartRepo)),
        ChangeNotifierProvider(create: (_) => OrderProvider(orderRepository: orderRepo)),
        // SearchProvider chưa có repo thì tạo bình thường
        //ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => RecentlyViewedProvider(recentlyViewedDao: recentlyViewedDao)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Đọc trạng thái Auth để quyết định trang khởi đầu
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return MaterialApp(
      title: 'Cửa Hàng Hoa Sen Đá',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Plus Jakarta Sans',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // Nếu đã login thì vào Home, ngược lại vào Login
      initialRoute: auth.isAuthenticated ? RouteNames.home : RouteNames.login,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
