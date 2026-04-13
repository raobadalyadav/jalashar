import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import '../auth/user_role.dart';
import '../models/models.dart';
import '../../features/admin/admin_shell.dart';
import '../../features/auth/phone_otp_screen.dart';
import '../../features/auth/role_selection_screen.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/client/booking_flow_screen.dart';
import '../../features/client/client_shell.dart';
import '../../features/client/vendor_detail_screen.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/vendor/vendor_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStream = Supabase.instance.client.auth.onAuthStateChange;

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authStream),
    redirect: (context, state) async {
      final session = Supabase.instance.client.auth.currentSession;
      final loc = state.matchedLocation;
      final isSplash = loc == '/splash';
      final isAuth = loc.startsWith('/auth');

      if (session == null) {
        return isAuth ? null : '/auth/sign-in';
      }

      final user = await ref.read(currentUserProvider.future);
      if (user == null) return '/auth/role';
      if (isSplash || loc == '/auth/sign-in') {
        return switch (user.role) {
          UserRole.vendor => '/vendor',
          UserRole.admin || UserRole.superAdmin || UserRole.support => '/admin',
          _ => '/home',
        };
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/auth/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(path: '/auth/phone', builder: (_, _) => const PhoneOtpScreen()),
      GoRoute(path: '/auth/role', builder: (_, _) => const RoleSelectionScreen()),
      GoRoute(path: '/home', builder: (_, _) => const ClientShell()),
      GoRoute(
        path: '/vendor-detail/:id',
        builder: (_, state) => VendorDetailScreen(vendor: state.extra as Vendor),
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
        path: '/chat/:bookingId/:receiverId',
        builder: (_, state) => ChatScreen(
          bookingId: state.pathParameters['bookingId']!,
          receiverId: state.pathParameters['receiverId']!,
        ),
      ),
      GoRoute(path: '/vendor', builder: (_, _) => const VendorShell()),
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
