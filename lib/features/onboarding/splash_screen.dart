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
    Future.microtask(_run);
  }

  Future<void> _run() async {
    debugPrint('[SPLASH] _run started');
    await Future.delayed(const Duration(milliseconds: 1800));
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
            colors: [
              AppColors.violetDeep,
              AppColors.violet,
              Color(0xFF9333EA),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.celebration, size: 52, color: Colors.white),
              )
                  .animate()
                  .scale(duration: 700.ms, curve: Curves.elasticOut),
              const SizedBox(height: 28),
              const Text(
                'Jalaram Events',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
              const SizedBox(height: 8),
              const Text(
                'Celebrate. Plan. Remember.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ).animate().fadeIn(delay: 600.ms),
              const Spacer(flex: 2),
              // Loading dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(
                      color: Colors.white54,
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .fadeIn(delay: Duration(milliseconds: i * 200))
                      .then()
                      .fadeOut(duration: 600.ms)
                      .then()
                      .fadeIn();
                }),
              ).animate().fadeIn(delay: 800.ms),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: const Text(
                  'By Jalaram Enterprises',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ).animate().fadeIn(delay: 1000.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
