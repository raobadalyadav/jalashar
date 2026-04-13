import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  final _slides = const [
    (
      'Plan Unforgettable Events',
      'From weddings to corporate gatherings, book trusted vendors in a few taps.',
      Icons.celebration_outlined,
    ),
    (
      'Verified Vendors',
      'Photographers, DJs, decorators and more — all verified, rated and reviewed.',
      Icons.verified_user_outlined,
    ),
    (
      'Secure Payments',
      'Pay 30% advance, confirm bookings instantly with secure UPI and cards.',
      Icons.lock_outline,
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go('/auth/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) {
                  final (title, body, icon) = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [AppColors.saffron, AppColors.deepMaroon],
                            ),
                          ),
                          child: Icon(icon, size: 80, color: Colors.white),
                        ),
                        const SizedBox(height: 40),
                        Text(title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Text(body,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? AppColors.saffron : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(children: [
                TextButton(onPressed: _finish, child: const Text('Skip')),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(140, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    if (_page == _slides.length - 1) {
                      _finish();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(_page == _slides.length - 1 ? 'Get Started' : 'Next'),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
