import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/theme/app_theme.dart';

class EmailOtpScreen extends ConsumerStatefulWidget {
  const EmailOtpScreen({super.key});
  @override
  ConsumerState<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends ConsumerState<EmailOtpScreen> {
  final _email = TextEditingController();
  final _otp = TextEditingController();
  bool _sent = false;
  bool _loading = false;

  Future<void> _send() async {
    if (_email.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider).sendEmailOtp(_email.text.trim());
      setState(() => _sent = true);
      _snack('6-digit code sent to ${_email.text}');
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    if (_otp.text.trim().length < 6) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authControllerProvider)
          .verifyEmailOtp(_email.text.trim(), _otp.text.trim());
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in with Email')),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.mail_outline, size: 64, color: AppColors.saffron),
            const SizedBox(height: 16),
            Text(
              _sent ? 'Enter the 6-digit code' : 'Enter your email',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _sent
                  ? 'We sent a verification code to ${_email.text}'
                  : "We'll email you a 6-digit verification code",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _email,
              enabled: !_sent,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                hintText: 'you@example.com',
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            if (_sent) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _otp,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofillHints: const [AutofillHints.oneTimeCode],
                style: const TextStyle(
                    fontSize: 28, letterSpacing: 8, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : (_sent ? _verify : _send),
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_sent ? 'Verify' : 'Send Code'),
            ),
            if (_sent) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loading ? null : _send,
                child: const Text('Resend code'),
              ),
              TextButton(
                onPressed: () => setState(() => _sent = false),
                child: const Text('Change email'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
