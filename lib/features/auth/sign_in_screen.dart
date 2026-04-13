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
  final _email = TextEditingController();
  final _password = TextEditingController();
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
              const SizedBox(height: 32),
              Text('auth.welcome'.tr(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700, color: AppColors.deepMaroon)),
              const SizedBox(height: 8),
              Text('auth.subtitle'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 32),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'auth.email'.tr(),
                  prefixIcon: const Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'auth.password'.tr(),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading
                    ? null
                    : () => _run(() =>
                        auth.signInWithEmail(_email.text.trim(), _password.text)),
                child: _loading
                    ? const SizedBox(
                        height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('auth.sign_in'.tr()),
              ),
              const SizedBox(height: 24),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('auth.or'.tr())),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 20),
              _ProviderButton(
                icon: Icons.g_mobiledata,
                label: 'auth.continue_google'.tr(),
                onTap: () => _run(() => auth.signInWithGoogle()),
              ),
              const SizedBox(height: 12),
              _ProviderButton(
                icon: Icons.apple,
                label: 'auth.continue_apple'.tr(),
                onTap: () => _run(() async => auth.signInWithApple()),
              ),
              const SizedBox(height: 12),
              _ProviderButton(
                icon: Icons.phone_android,
                label: 'auth.continue_phone'.tr(),
                onTap: () => context.push('/auth/phone'),
              ),
              const Spacer(),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text('auth.no_account_signup'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 24),
      label: Text(label),
    );
  }
}
