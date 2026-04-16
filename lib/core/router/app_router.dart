import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../../features/admin/admin_shell.dart';
import '../../features/auth/email_otp_screen.dart';
import '../../features/auth/role_selection_screen.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/client/booking_confirmation_screen.dart';
import '../../features/client/booking_flow_screen.dart';
import '../../features/client/checklist_screen.dart';
import '../../features/client/client_shell.dart';
import '../../features/client/compare_vendors_screen.dart';
import '../../features/client/edit_profile_screen.dart';
import '../../features/client/faq_screen.dart';
import '../../features/client/privacy_policy_screen.dart';
import '../../features/client/referral_screen.dart';
import '../../features/client/review_screen.dart';
import '../../features/client/search_screen.dart';
import '../../features/client/service_detail_screen.dart';
import '../../features/client/settings_screen.dart';
import '../../features/client/support_screen.dart';
import '../../features/client/terms_screen.dart';
import '../../features/client/vendor_detail_screen.dart';
import '../../features/client/wishlist_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/vendor/availability_screen.dart';
import '../../features/vendor/payouts_screen.dart';
import '../../features/vendor/vendor_packages_screen.dart';
import '../../features/vendor/vendor_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStream = Supabase.instance.client.auth.onAuthStateChange;

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authStream),
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final loc = state.matchedLocation;
      final isSplash = loc == '/splash';
      final isOnboarding = loc == '/onboarding';
      final isAuth = loc.startsWith('/auth');

      if (isSplash || isOnboarding) return null;
      if (session == null) return isAuth ? null : '/auth/sign-in';
      if (loc == '/auth/sign-in') return '/splash';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/auth/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(path: '/auth/email-otp', builder: (_, _) => const EmailOtpScreen()),
      GoRoute(path: '/auth/role', builder: (_, _) => const RoleSelectionScreen()),

      // ── Client ──────────────────────────────────────────────────────────
      GoRoute(path: '/home', builder: (_, _) => const ClientShell()),
      GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
      GoRoute(
        path: '/service/:slug',
        builder: (_, state) =>
            ServiceDetailScreen(service: state.extra as ServicePackage),
      ),
      GoRoute(
        path: '/vendor-detail/:id',
        builder: (_, state) =>
            VendorDetailScreen(vendor: state.extra as Vendor),
      ),
      GoRoute(
        path: '/booking/new',
        builder: (_, state) {
          final extra = state.extra;
          return BookingFlowScreen(
            vendor: extra is Vendor ? extra : null,
            service: extra is ServicePackage ? extra : null,
          );
        },
      ),
      GoRoute(
        path: '/booking/confirm/:bookingId',
        builder: (_, state) => BookingConfirmationScreen(
          bookingId: state.pathParameters['bookingId']!,
        ),
      ),
      GoRoute(
        path: '/checklist/:bookingId',
        builder: (_, state) => ChecklistScreen(
          bookingId: state.pathParameters['bookingId']!,
          eventType: state.uri.queryParameters['eventType'],
        ),
      ),
      GoRoute(
        path: '/chat/:bookingId/:receiverId',
        builder: (_, state) => ChatScreen(
          bookingId: state.pathParameters['bookingId']!,
          receiverId: state.pathParameters['receiverId']!,
        ),
      ),
      GoRoute(
        path: '/review/:bookingId/:vendorId',
        builder: (_, state) => ReviewScreen(
          bookingId: state.pathParameters['bookingId']!,
          vendorId: state.pathParameters['vendorId']!,
        ),
      ),
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: '/wishlist', builder: (_, _) => const WishlistScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/profile/edit', builder: (_, _) => const EditProfileScreen()),
      GoRoute(path: '/faq', builder: (_, _) => const FaqScreen()),
      GoRoute(path: '/support', builder: (_, _) => const SupportScreen()),
      GoRoute(path: '/referral', builder: (_, _) => const ReferralScreen()),
      GoRoute(path: '/privacy-policy', builder: (_, _) => const PrivacyPolicyScreen()),
      GoRoute(path: '/terms', builder: (_, _) => const TermsScreen()),
      GoRoute(path: '/compare', builder: (_, _) => const CompareVendorsScreen()),

      // ── Vendor ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/vendor/availability/:vendorId',
        builder: (_, state) => AvailabilityScreen(
          vendorId: state.pathParameters['vendorId']!,
        ),
      ),
      GoRoute(path: '/vendor/payouts', builder: (_, _) => const PayoutsScreen()),
      GoRoute(path: '/vendor/packages', builder: (_, _) => const VendorPackagesScreen()),
      GoRoute(path: '/vendor', builder: (_, _) => const VendorShell()),

      // ── Admin ────────────────────────────────────────────────────────────
      GoRoute(path: '/admin', builder: (_, _) => const AdminShell()),
    ],
    errorBuilder: (_, state) =>
        Scaffold(body: Center(child: Text('Route error: ${state.error}'))),
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
