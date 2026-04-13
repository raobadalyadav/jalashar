import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';

class PhoneOtpScreen extends ConsumerStatefulWidget {
  const PhoneOtpScreen({super.key});
  @override
  ConsumerState<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends ConsumerState<PhoneOtpScreen> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  bool _sent = false;
  bool _loading = false;

  Future<void> _send() async {
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider).sendPhoneOtp(_phone.text.trim());
      setState(() => _sent = true);
    } catch (e) {
      _snack(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(authControllerProvider)
          .verifyPhoneOtp(_phone.text.trim(), _otp.text.trim());
    } catch (e) {
      _snack(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('auth.continue_phone'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.phone),
                hintText: '+91 98765 43210',
              ),
            ),
            const SizedBox(height: 16),
            if (_sent)
              TextField(
                controller: _otp,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.pin),
                  hintText: '6-digit code',
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : (_sent ? _verify : _send),
              child: Text(_loading ? '...' : (_sent ? 'Verify' : 'Send OTP')),
            ),
          ],
        ),
      ),
    );
  }
}
