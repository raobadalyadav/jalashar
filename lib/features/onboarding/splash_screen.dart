import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/user_role.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[SPLASH] initState');
    // Fire regardless of framework timing
    Future.microtask(_run);
  }

  Future<void> _run() async {
    debugPrint('[SPLASH] _run started');
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted || _navigated) return;

    String target;
    try {
      bool onboardingDone = false;
      try {
        final prefs = await SharedPreferences.getInstance()
            .timeout(const Duration(seconds: 2));
        onboardingDone = prefs.getBool('onboarding_done') ?? false;
        debugPrint('[SPLASH] onboardingDone=$onboardingDone');
      } catch (e) {
        debugPrint('[SPLASH] prefs error: $e');
      }

      final session = Supabase.instance.client.auth.currentSession;
      debugPrint('[SPLASH] session=${session != null}');

      if (session == null) {
        target = onboardingDone ? '/auth/sign-in' : '/onboarding';
      } else {
        String? roleStr;
        try {
          final row = await Supabase.instance.client
              .from('users')
              .select('role')
              .eq('id', session.user.id)
              .maybeSingle()
              .timeout(const Duration(seconds: 5));
          roleStr = row?['role'] as String?;
          debugPrint('[SPLASH] role=$roleStr');
        } catch (e) {
          debugPrint('[SPLASH] role fetch failed: $e');
        }
        if (roleStr == null) {
          target = '/auth/role';
        } else {
          final role = UserRole.fromString(roleStr);
          target = switch (role) {
            UserRole.vendor => '/vendor',
            UserRole.admin || UserRole.superAdmin || UserRole.support => '/admin',
            _ => '/home',
          };
        }
      }
    } catch (e) {
      debugPrint('[SPLASH] unexpected error: $e');
      target = '/auth/sign-in';
    }

    if (!mounted || _navigated) return;
    _navigated = true;
    debugPrint('[SPLASH] navigating → $target');
    GoRouter.of(context).go(target);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[SPLASH] build');
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.saffron, AppColors.gold],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.celebration, size: 96, color: Colors.white)
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              const Text(
                'Jalaram Events',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
              const SizedBox(height: 8),
              const Text(
                'Celebrate. Plan. Remember.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 48),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
