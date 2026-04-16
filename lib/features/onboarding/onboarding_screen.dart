import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  static const _slides = [
    _Slide(
      title: 'Plan Unforgettable Events',
      body: 'From weddings to corporate gatherings, book trusted vendors in a few taps.',
      gradient: [AppColors.violetDeep, AppColors.violet],
      shape: _SlideShape.celebration,
    ),
    _Slide(
      title: 'Verified Vendors Only',
      body: 'Photographers, DJs, decorators and more — all verified, rated and reviewed.',
      gradient: [Color(0xFF1D4ED8), AppColors.violet],
      shape: _SlideShape.verify,
    ),
    _Slide(
      title: 'Secure & Instant Payments',
      body: 'Pay 30% advance to confirm. UPI, cards, net banking — all secured.',
      gradient: [AppColors.violet, Color(0xFFBE185D)],
      shape: _SlideShape.payment,
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go('/auth/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _slides[_page].gradient
                    .map((c) => c.withValues(alpha: 0.12))
                    .toList(),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton(
                      onPressed: _finish,
                      child: const Text('Skip',
                          style: TextStyle(color: AppColors.slate)),
                    ),
                  ),
                ),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: _slides.length,
                    itemBuilder: (_, i) {
                      final slide = _slides[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Illustration
                            _Illustration(
                              shape: slide.shape,
                              gradient: slide.gradient,
                              size: size.width * 0.72,
                            )
                                .animate(key: ValueKey(i))
                                .scale(
                                    duration: 600.ms,
                                    curve: Curves.elasticOut)
                                .fadeIn(),
                            const SizedBox(height: 48),

                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.charcoal,
                                    letterSpacing: -0.3,
                                  ),
                            )
                                .animate(key: ValueKey('t$i'))
                                .fadeIn(delay: 200.ms)
                                .slideY(begin: 0.2),

                            const SizedBox(height: 14),

                            Text(
                              slide.body,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: AppColors.slate,
                                    height: 1.6,
                                  ),
                            )
                                .animate(key: ValueKey('b$i'))
                                .fadeIn(delay: 300.ms),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _page == i ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: _page == i
                            ? LinearGradient(colors: _slides[_page].gradient)
                            : null,
                        color: _page == i ? null : AppColors.violetMid,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                // Navigation buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
                  child: SizedBox(
                    height: 56,
                    child: _page == _slides.length - 1
                        ? _GradientNavButton(
                            label: 'Get Started',
                            gradient: LinearGradient(
                                colors: _slides[_page].gradient),
                            onPressed: _finish,
                          )
                        : Row(children: [
                            // Prev
                            if (_page > 0)
                              OutlinedButton(
                                onPressed: () => _controller.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(80, 56),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: const Text('Back'),
                              ),
                            const Spacer(),
                            _GradientNavButton(
                              label: 'Next',
                              gradient: LinearGradient(
                                  colors: _slides[_page].gradient),
                              onPressed: () => _controller.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              ),
                            ),
                          ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────

enum _SlideShape { celebration, verify, payment }

class _Slide {
  const _Slide({
    required this.title,
    required this.body,
    required this.gradient,
    required this.shape,
  });
  final String title, body;
  final List<Color> gradient;
  final _SlideShape shape;
}

// ── Gradient Nav Button ───────────────────────────────────────────────────────

class _GradientNavButton extends StatelessWidget {
  const _GradientNavButton({
    required this.label,
    required this.gradient,
    required this.onPressed,
  });
  final String label;
  final Gradient gradient;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56,
        constraints: const BoxConstraints(minWidth: 160),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.violet.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Illustrations (No generic icons — custom shapes) ─────────────────────────

class _Illustration extends StatelessWidget {
  const _Illustration({
    required this.shape,
    required this.gradient,
    required this.size,
  });
  final _SlideShape shape;
  final List<Color> gradient;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.85,
      child: CustomPaint(
        painter: _IllustrationPainter(shape: shape, gradient: gradient),
      ),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  const _IllustrationPainter({required this.shape, required this.gradient});
  final _SlideShape shape;
  final List<Color> gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final g = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: gradient,
    );

    switch (shape) {
      case _SlideShape.celebration:
        _paintCelebration(canvas, size, g);
      case _SlideShape.verify:
        _paintVerify(canvas, size, g);
      case _SlideShape.payment:
        _paintPayment(canvas, size, g);
    }
  }

  void _paintCelebration(Canvas canvas, Size s, LinearGradient g) {
    final paint = Paint()..shader = g.createShader(Offset.zero & s);
    // Central circle (event hall)
    canvas.drawCircle(Offset(s.width / 2, s.height / 2), s.width * 0.3, paint);

    // Decorative rings
    final ringPaint = Paint()
      ..shader = g.createShader(Offset.zero & s)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(
        Offset(s.width / 2, s.height / 2), s.width * 0.38, ringPaint);
    canvas.drawCircle(
        Offset(s.width / 2, s.height / 2), s.width * 0.46, ringPaint..strokeWidth = 1.5);

    // Accent dots (confetti-like)
    final dotPaint = Paint()..color = gradient.last.withValues(alpha: 0.7);
    for (var i = 0; i < 8; i++) {
      final angle = (i / 8) * 3.14159 * 2;
      final r = s.width * 0.46;
      canvas.drawCircle(
        Offset(s.width / 2 + r * _cos(angle), s.height / 2 + r * _sin(angle)),
        6,
        dotPaint,
      );
    }

    // Star shapes for celebration
    final starPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    _drawStar(canvas, Offset(s.width * 0.18, s.height * 0.2), 16, starPaint);
    _drawStar(canvas, Offset(s.width * 0.82, s.height * 0.15), 12, starPaint);
    _drawStar(canvas, Offset(s.width * 0.75, s.height * 0.78), 10, starPaint);
    _drawStar(canvas, Offset(s.width * 0.15, s.height * 0.75), 14, starPaint);

    // Calligraphy-like "J" in center
    final textPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final path = Path();
    final cx = s.width / 2;
    final cy = s.height / 2;
    path.moveTo(cx - 20, cy - 30);
    path.lineTo(cx + 20, cy - 30);
    path.moveTo(cx, cy - 30);
    path.lineTo(cx, cy + 15);
    path.quadraticBezierTo(cx, cy + 35, cx - 20, cy + 30);
    canvas.drawPath(path, textPaint);
  }

  void _paintVerify(Canvas canvas, Size s, LinearGradient g) {
    final paint = Paint()..shader = g.createShader(Offset.zero & s);

    // Shield shape
    final path = Path();
    final cx = s.width / 2;
    final cy = s.height * 0.45;
    final w = s.width * 0.55;
    final h = s.height * 0.65;
    path.moveTo(cx, cy - h / 2);
    path.lineTo(cx + w / 2, cy - h * 0.3);
    path.lineTo(cx + w / 2, cy + h * 0.1);
    path.quadraticBezierTo(cx + w / 2, cy + h / 2, cx, cy + h / 2);
    path.quadraticBezierTo(cx - w / 2, cy + h / 2, cx - w / 2, cy + h * 0.1);
    path.lineTo(cx - w / 2, cy - h * 0.3);
    path.close();
    canvas.drawPath(path, paint);

    // Checkmark
    final checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final checkPath = Path();
    checkPath.moveTo(cx - w * 0.22, cy + h * 0.05);
    checkPath.lineTo(cx - w * 0.04, cy + h * 0.22);
    checkPath.lineTo(cx + w * 0.25, cy - h * 0.12);
    canvas.drawPath(checkPath, checkPaint);

    // Stars around
    final starPaint = Paint()..color = gradient.first.withValues(alpha: 0.5);
    _drawStar(canvas, Offset(s.width * 0.12, s.height * 0.3), 12, starPaint);
    _drawStar(canvas, Offset(s.width * 0.88, s.height * 0.25), 14, starPaint);
    _drawStar(canvas, Offset(s.width * 0.2, s.height * 0.72), 10, starPaint);
    _drawStar(canvas, Offset(s.width * 0.85, s.height * 0.7), 12, starPaint);

    // Rating dots at bottom
    final dotPaint = Paint()..color = gradient.last;
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(cx - 40 + i * 20.0, s.height * 0.9),
        6,
        dotPaint,
      );
    }
  }

  void _paintPayment(Canvas canvas, Size s, LinearGradient g) {
    final paint = Paint()..shader = g.createShader(Offset.zero & s);

    // Card shape
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(s.width / 2, s.height * 0.42),
          width: s.width * 0.78,
          height: s.height * 0.46),
      const Radius.circular(20),
    );
    canvas.drawRRect(cardRect, paint);

    // Card stripe
    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2);
    canvas.drawRect(
      Rect.fromLTWH(
          s.width / 2 - s.width * 0.39, s.height * 0.3, s.width * 0.78, 24),
      stripePaint,
    );

    // Chip
    final chipPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.17, s.height * 0.37, 50, 36),
        const Radius.circular(6),
      ),
      chipPaint,
    );

    // Lock icon (circles + body)
    final lockPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final lx = s.width / 2;
    final ly = s.height * 0.74;
    canvas.drawArc(
        Rect.fromCircle(center: Offset(lx, ly - 18), radius: 18),
        3.14, 3.14, false, lockPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(lx, ly + 10), width: 40, height: 32),
          const Radius.circular(6)),
      lockPaint..style = PaintingStyle.fill..color = gradient.last,
    );
    canvas.drawCircle(Offset(lx, ly + 12), 5,
        Paint()..color = Colors.white);

    // Rupee symbols floating
    final rupeeStyle = Paint()
      ..color = gradient.first.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    _drawRupee(canvas, Offset(s.width * 0.12, s.height * 0.15), 16, rupeeStyle);
    _drawRupee(canvas, Offset(s.width * 0.85, s.height * 0.12), 12, rupeeStyle);
    _drawRupee(canvas, Offset(s.width * 0.9, s.height * 0.65), 14, rupeeStyle);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  double _cos(double a) => _mathCos(a);
  double _sin(double a) => _mathSin(a);

  static double _mathCos(double a) {
    // Taylor series approximation
    double x = a % (2 * 3.14159265358979);
    return 1 - (x * x) / 2 + (x * x * x * x) / 24;
  }

  static double _mathSin(double a) {
    double x = a % (2 * 3.14159265358979);
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }

  void _drawStar(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * 3.14159 / 180;
      final innerAngle = ((i * 72 + 36) - 90) * 3.14159 / 180;
      final outer = Offset(
        center.dx + r * _cos(outerAngle),
        center.dy + r * _sin(outerAngle),
      );
      final inner = Offset(
        center.dx + r * 0.45 * _cos(innerAngle),
        center.dy + r * 0.45 * _sin(innerAngle),
      );
      if (i == 0) {
        path.moveTo(outer.dx, outer.dy);
      } else {
        path.lineTo(outer.dx, outer.dy);
      }
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawRupee(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx - size * 0.5, center.dy - size * 0.6);
    path.lineTo(center.dx + size * 0.5, center.dy - size * 0.6);
    path.moveTo(center.dx - size * 0.5, center.dy - size * 0.2);
    path.lineTo(center.dx + size * 0.5, center.dy - size * 0.2);
    path.moveTo(center.dx - size * 0.5, center.dy - size * 0.2);
    path.lineTo(center.dx - size * 0.5, center.dy - size * 0.6);
    path.quadraticBezierTo(
      center.dx + size * 0.5, center.dy - size * 0.6,
      center.dx + size * 0.5, center.dy - size * 0.4,
    );
    path.quadraticBezierTo(
      center.dx + size * 0.5, center.dy - size * 0.1,
      center.dx - size * 0.5, center.dy - size * 0.2,
    );
    path.moveTo(center.dx - size * 0.3, center.dy - size * 0.15);
    path.lineTo(center.dx + size * 0.4, center.dy + size * 0.7);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _IllustrationPainter old) =>
      old.shape != shape || old.gradient != gradient;
}
