import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/main_shell.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/products/product_list_screen.dart';
import '../screens/products/product_detail_screen.dart';
import '../screens/products/category_list_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/orders/order_detail_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/inquiry/product_inquiry_screen.dart';
import '../screens/messages/messages_screen.dart';
import '../screens/messages/chat_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/addresses_screen.dart';

class AppRouter {
  static GoRouter router(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: auth,
      redirect: (context, state) {
        final isAuth = auth.isAuthenticated;
        final isLoading = auth.isLoading;
        final isLoginRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        if (isLoading) return null;

        // If not authenticated and trying to access protected routes
        if (!isAuth && !isLoginRoute) {
          final protectedPaths = [
            '/checkout',
            '/orders',
            '/messages',
            '/profile'
          ];
          for (final path in protectedPaths) {
            if (state.matchedLocation.startsWith(path)) {
              return '/login';
            }
          }
        }

        // If authenticated and on login page, go home
        if (isAuth && isLoginRoute) return '/';

        return null;
      },
      routes: [
        // Main shell with bottom navigation
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const HomeScreen(),
            ),
            GoRoute(
              path: '/products',
              builder: (_, __) => const ProductListScreen(),
            ),
            GoRoute(
              path: '/cart',
              builder: (_, __) => const CartScreen(),
            ),
            GoRoute(
              path: '/orders',
              builder: (_, __) => const OrdersScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (_, __) => const ProfileScreen(),
            ),
          ],
        ),
        // Auth routes (no shell)
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (_, __) => const RegisterScreen(),
        ),
        // Product detail
        GoRoute(
          path: '/product/:id',
          builder: (_, state) => ProductDetailScreen(
            productId: state.pathParameters['id']!,
          ),
        ),
        // Categories
        GoRoute(
          path: '/categories',
          builder: (_, __) => const CategoryListScreen(),
        ),
        // Checkout
        GoRoute(
          path: '/checkout',
          builder: (_, __) => const CheckoutScreen(),
        ),
        // Order detail
        GoRoute(
          path: '/order/:id',
          builder: (_, state) => OrderDetailScreen(
            orderId: state.pathParameters['id']!,
          ),
        ),
        // Search
        GoRoute(
          path: '/search',
          builder: (_, __) => const SearchScreen(),
        ),
        // Product Inquiry chat
        GoRoute(
          path: '/inquiry',
          builder: (_, state) => ProductInquiryScreen(
            initialQuery: state.uri.queryParameters['q'],
          ),
        ),
        // Messages/Chat
        GoRoute(
          path: '/messages',
          builder: (_, __) => const MessagesScreen(),
        ),
        GoRoute(
          path: '/chat/:id',
          builder: (_, state) => ChatScreen(
            conversationId: state.pathParameters['id']!,
          ),
        ),
        // Profile sub-routes
        GoRoute(
          path: '/profile/edit',
          builder: (_, __) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/profile/addresses',
          builder: (_, __) => const AddressesScreen(),
        ),
      ],
      errorBuilder: (_, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Page not found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => GoRouter.of(_).go('/'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
