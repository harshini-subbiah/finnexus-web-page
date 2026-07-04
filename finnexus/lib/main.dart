import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/onboarding/role_selection_screen.dart';
import 'screens/onboarding/business_details_screen.dart';
import 'screens/onboarding/kyc_upload_screen.dart';
import 'screens/onboarding/pending_review_screen.dart';
import 'screens/dashboard/unified_dashboard_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/financial/loan_application_screen.dart';
import 'screens/financial/my_loans_screen.dart';
import 'screens/financial/insurance_application_screen.dart';
import 'screens/financial/my_insurance_screen.dart';
import 'screens/ecommerce/product_catalogue_screen.dart';
import 'screens/ecommerce/cart_screen.dart';
import 'screens/ecommerce/payment_screen.dart';
import 'screens/ecommerce/order_confirmed_screen.dart';
import 'screens/ecommerce/my_orders_screen.dart';
import 'screens/ecommerce/vendor_products_screen.dart';
import 'screens/logistics/logistics_screen.dart';
import 'screens/advisory/advisory_request_screen.dart';
import 'screens/advisory/my_advisory_screen.dart';
import 'screens/advisory/advisor_sessions_screen.dart';
import 'screens/advisory/session_screen.dart';
import 'screens/ecommerce/product_chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FinNexusApp());
}

const List<String> _adminEmails = ['admin@finnexus.com'];

// Routes that don't require login
const List<String> _publicRoutes = ['/', '/login', '/register'];

final _router = GoRouter(
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges()),
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final goingTo = state.matchedLocation;
    final isPublic = _publicRoutes.contains(goingTo);

    // Not logged in, trying to access a protected page → force login
    if (user == null && !isPublic) {
      return '/login';
    }

    // Logged in, trying to access login/register → force dashboard
    // This is what stops forward-button replay from working
    if (user != null &&
        (goingTo == '/login' || goingTo == '/register')) {
      if (_adminEmails.contains(user.email)) {
        return '/admin/dashboard';
      }
      return '/dashboard';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/role', builder: (_, __) => const RoleSelectionScreen()),
    GoRoute(path: '/business', builder: (_, __) => const BusinessDetailsScreen()),
    GoRoute(path: '/kyc', builder: (_, __) => const KycUploadScreen()),
    GoRoute(path: '/pending', builder: (_, __) => const PendingReviewScreen()),
    GoRoute(path: '/dashboard', builder: (_, __) => const UnifiedDashboardScreen()),
    GoRoute(path: '/admin/dashboard', builder: (_, __) => const AdminDashboardScreen()),
    GoRoute(path: '/loan-apply', builder: (_, __) => const LoanApplicationScreen()),
    GoRoute(path: '/loans', builder: (_, __) => const MyLoansScreen()),
    GoRoute(path: '/insurance', builder: (_, __) => const MyInsuranceScreen()),
    GoRoute(path: '/insurance-apply', builder: (_, __) => const InsuranceApplicationScreen()),
    GoRoute(path: '/catalogue', builder: (_, __) => const ProductCatalogueScreen()),
    GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
    GoRoute(path: '/payment', builder: (_, __) => const PaymentScreen()),
    GoRoute(path: '/order-confirmed', builder: (_, __) => const OrderConfirmedScreen()),
    GoRoute(path: '/my-orders', builder: (_, __) => const MyOrdersScreen()),
    GoRoute(path: '/my-products', builder: (_, __) => const VendorProductsScreen()),
    GoRoute(path: '/logistics', builder: (_, __) => const LogisticsScreen()),
    GoRoute(path: '/advisory-request', builder: (_, __) => const AdvisoryRequestScreen()),
    GoRoute(path: '/my-advisory', builder: (_, __) => const MyAdvisoryScreen()),
    GoRoute(path: '/advisor-sessions', builder: (_, __) => const AdvisorSessionsScreen()),
    GoRoute(path: '/session', builder: (_, __) => const SessionScreen()),
    GoRoute(path: '/product-chat', builder: (_, __) => const ProductChatScreen()),
  ],
);

// Bridges Firebase auth state changes into go_router so redirect
// re-evaluates immediately on sign-in/sign-out, not just on navigation
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class FinNexusApp extends StatelessWidget {
  const FinNexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FinNexus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A1A2E),
            brightness: Brightness.dark),
        textTheme: GoogleFonts.dmSansTextTheme(
            ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}