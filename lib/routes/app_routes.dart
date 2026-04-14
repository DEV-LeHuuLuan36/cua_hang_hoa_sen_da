import 'package:flutter/material.dart';
import '../utils/constants/route_names.dart';

// Tạm thời import các màn hình trống (Chúng ta sẽ code chi tiết ở bước sau)
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/customer/home/home_screen.dart';
import '../screens/admin/admin_add_edit_product.dart';
import '../screens/customer/product/product_detail_screen.dart';
import '../screens/customer/cart/cart_screen.dart';
import '../screens/customer/profile/address_book_screen.dart';
import '../screens/customer/cart/checkout_screen.dart';
import '../screens/customer/order/order_list_screen.dart';
import '../screens/customer/search/search_screen.dart';
import '../screens/customer/profile/wishlist_screen.dart';
import '../screens/admin/admin_order_screen.dart';
import '../screens/customer/order/order_detail_screen.dart';
import '../screens/customer/profile/my_vouchers_screen.dart';
import '../screens/customer/product/product_list_screen.dart';
import '../screens/admin/admin_report_screen.dart';

import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_product_screen.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case RouteNames.register: // <--- 2. Bổ sung case điều hướng này
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case RouteNames.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case RouteNames.adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case RouteNames.adminProductList:
        return MaterialPageRoute(builder: (_) => const AdminProductScreen());
    // Ví dụ: Nhận ID sản phẩm khi vào màn hình chi tiết
      case RouteNames.productDetail:
        final productId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: productId),
        );
      case RouteNames.adminAddEditProduct:
        final productId = settings.arguments as String?; // Nhận ID (null = thêm mới)
        return MaterialPageRoute(
          builder: (_) => AdminAddEditProductScreen(productId: productId),
        );
      case RouteNames.cart:
        return MaterialPageRoute(builder: (_) => const CartScreen()
        );
      case RouteNames.addressBook:
        return MaterialPageRoute(builder: (_) => const AddressBookScreen());
      case RouteNames.checkout:
        return MaterialPageRoute(builder: (_) => const CheckoutScreen());
      case RouteNames.orderList:
        return MaterialPageRoute(builder: (_) => const OrderListScreen());
      case '/search': // Hoặc RouteNames.search nếu bạn đã khai báo
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      case '/wishlist':
        return MaterialPageRoute(builder: (_) => const WishlistScreen());
      case '/admin-order-list':
        return MaterialPageRoute(builder: (_) => const AdminOrderScreen());
      case '/order-detail':
        return MaterialPageRoute(builder: (_) => const OrderDetailScreen());
      case '/my-vouchers':
        return MaterialPageRoute(builder: (_) => const MyVouchersScreen());
      case '/product-list':
        return MaterialPageRoute(builder: (_) => const ProductListScreen());
      case '/admin-report':
        return MaterialPageRoute(builder: (_) => const AdminReportScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Không tìm thấy trang: ${settings.name}')),
          ),
        );
    }
  }
}