import 'package:flutter/material.dart';
import '../screens/customer/profile/profile/my_reviews_screen.dart';
import '../screens/customer/profile/settings_screen.dart';
import '../screens/customer/support/support_screen.dart';
import '../screens/customer/legal/legal_screen.dart';
import '../screens/customer/notification/notification_screen.dart';
import '../utils/constants/route_names.dart';

// Auth
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';

// Customer
import '../screens/customer/home/home_screen.dart';
import '../screens/customer/product/product_detail_screen.dart';
import '../screens/customer/product/product_list_screen.dart';
import '../screens/customer/cart/cart_screen.dart';
import '../screens/customer/cart/checkout_screen.dart';
import '../screens/customer/search/search_screen.dart';
import '../screens/customer/order/order_list_screen.dart';
import '../screens/customer/order/order_detail_screen.dart';
import '../screens/customer/profile/profile_screen.dart';
import '../screens/customer/profile/address_book_screen.dart';
import '../screens/customer/profile/wishlist_screen.dart';
import '../screens/customer/profile/my_vouchers_screen.dart';
import '../screens/customer/profile/recently_viewed_screen.dart';
import '../screens/customer/profile/add_edit_address_screen.dart';

// Admin
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_product_screen.dart';
import '../screens/admin/admin_add_edit_product.dart';
import '../screens/admin/admin_order_screen.dart';
import '../screens/admin/admin_report_screen.dart';
import '../screens/admin/admin_voucher_screen.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
    // --- AUTH ROUTES ---
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case RouteNames.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

    // --- CUSTOMER ROUTES ---
      case RouteNames.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case RouteNames.productDetail:
        final productId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: productId),
        );

      case RouteNames.productList:
        return MaterialPageRoute(builder: (_) => const ProductListScreen());

      case RouteNames.search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());

      case RouteNames.cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());

      case RouteNames.checkout:
        return MaterialPageRoute(builder: (_) => const CheckoutScreen());

      case RouteNames.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case RouteNames.addressBook:
        return MaterialPageRoute(builder: (_) => const AddressBookScreen());

      case RouteNames.wishlist:
        return MaterialPageRoute(builder: (_) => const WishlistScreen());

      case RouteNames.myVouchers:
        return MaterialPageRoute(builder: (_) => const MyVouchersScreen());

      case RouteNames.recentlyViewed:
        return MaterialPageRoute(builder: (_) => const RecentlyViewedScreen());

      case RouteNames.orderList:
        return MaterialPageRoute(builder: (_) => const OrderListScreen());

      case RouteNames.orderDetail:
        final orderId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) =>  OrderDetailScreen(orderId: orderId),);

    // --- ADMIN ROUTES ---
      case RouteNames.adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());

      case RouteNames.adminProductList:
        return MaterialPageRoute(builder: (_) => const AdminProductScreen());

      case RouteNames.adminAddEditProduct:
        final productId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => AdminAddEditProductScreen(productId: productId),
        );

      case RouteNames.adminOrderList:
        return MaterialPageRoute(builder: (_) => const AdminOrderScreen());

      case RouteNames.adminReport:
        return MaterialPageRoute(builder: (_) => const AdminReportScreen());

      case RouteNames.adminVoucher:
        return MaterialPageRoute(builder: (_) => const AdminVoucherScreen());

      case '${RouteNames.addressBook}/add':
        return MaterialPageRoute(builder: (_) => const AddEditAddressScreen());
      case '${RouteNames.addressBook}/edit':
        final addressId = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => AddEditAddressScreen(addressId: addressId));

      case RouteNames.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case RouteNames.myReviews:
        return MaterialPageRoute(builder: (_) => const MyReviewsScreen());
      case RouteNames.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationScreen());
      case RouteNames.support:
        return MaterialPageRoute(builder: (_) => const SupportScreen());
      case RouteNames.legal:
        return MaterialPageRoute(builder: (_) => const LegalScreen());
    // --- DEFAULT ---
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Không tìm thấy trang: ${settings.name}'),
            ),
          ),
        );
    }
  }
}