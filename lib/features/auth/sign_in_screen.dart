import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/theme/app_theme.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});
  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _loading = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.saffron, AppColors.deepMaroon],
                  ),
                ),
                child: const Icon(Icons.celebration,
                    color: Colors.white, size: 52),
              ),
              const SizedBox(height: 24),
              Text('auth.welcome'.tr(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700, color: AppColors.deepMaroon)),
              const SizedBox(height: 8),
              Text('auth.subtitle'.tr(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              _ProviderButton(
                icon: Icons.mail_outline,
                label: 'Continue with Email',
                color: AppColors.deepMaroon,
                onTap: _loading ? null : () => context.push('/auth/email-otp'),
              ),
              const SizedBox(height: 12),
              _ProviderButton(
                icon: Icons.g_mobiledata,
                iconSize: 32,
                label: 'Continue with Google',
                color: const Color(0xFFDB4437),
                onTap: _loading ? null : () => _run(() => auth.signInWithGoogle()),
              ),
              const SizedBox(height: 12),
              _ProviderButton(
                icon: Icons.facebook,
                label: 'Continue with Facebook',
                color: const Color(0xFF1877F2),
                onTap: _loading
                    ? null
                    : () async {
                        try {
                          await _run(() => auth.signInWithFacebook());
                        } catch (_) {}
                      },
              ),
              const SizedBox(height: 24),
              if (_loading) const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              Text(
                'By continuing, you agree to our Terms & Privacy Policy.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.iconSize = 22,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.4)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: Icon(icon, size: iconSize, color: color),
        label: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
