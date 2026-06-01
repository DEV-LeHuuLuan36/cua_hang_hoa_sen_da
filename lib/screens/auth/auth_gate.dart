import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/customer/home/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // FutureBuilder in main.dart already blocked rendering until tryAutoLogin() completed.
        // At this point _currentUser is fully loaded. If null, user must log in.
        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        // Strict role check: email/username overrides DB role
        if (auth.isAdmin) {
          return const AdminDashboardScreen();
        }

        return const CustomerShell();
      },
    );
  }
}
