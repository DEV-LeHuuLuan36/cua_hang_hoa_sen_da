import 'package:cua_hang_hoa_sen_da/routes/app_routes.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// 1. Import DAOs
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
void main() {
  // Đảm bảo các widget binding của Flutter được khởi tạo trước khi gọi SQLite
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    // Khởi tạo FFI
    sqfliteFfiInit();
    // Đổi databaseFactory sang FFI
    databaseFactory = databaseFactoryFfi;
  }

  // BƯỚC 1: KHỞI TẠO DAOs
  final userDao = UserDao();
  final productDao = ProductDao();
  final categoryDao = CategoryDao();
  final cartDao = CartDao();
  final orderDao = OrderDao();

  // BƯỚC 2: KHỞI TẠO REPOSITORIES (Bơm DAO vào Repository)
  final authRepo = AuthRepository(userDao: userDao);
  final productRepo = ProductRepository(productDao: productDao, categoryDao: categoryDao);
  final cartRepo = CartRepository(cartDao: cartDao);
  final orderRepo = OrderRepository(orderDao: orderDao);

  // BƯỚC 3: CHẠY APP VỚI MULTIPROVIDER
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository: authRepo)),
        ChangeNotifierProvider(create: (_) => ProductProvider(productRepository: productRepo)),
        ChangeNotifierProvider(create: (_) => CartProvider(cartRepository: cartRepo)),
        ChangeNotifierProvider(create: (_) => OrderProvider(orderRepository: orderRepo)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cửa Hàng Hoa Sen Đá',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Gọi font chữ đã cấu hình trong pubspec.yaml
        fontFamily: 'Plus Jakarta Sans',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      onGenerateRoute: AppRoutes.generateRoute,
      // Tạm thời hiển thị một màn hình trống báo thành công
      home: const Scaffold(
        body: Center(
          child: Text(
            '🎉 Thiết lập Nền Tảng Dữ Liệu Thành Công! 🎉\nSẵn sàng code Giao diện (UI)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}