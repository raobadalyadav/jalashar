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
      body: 'Weddings, birthdays, corporate — find and book trusted local vendors in minutes.',
      gradient: [AppColors.violetDeep, AppColors.violet],
      shape: _SlideShape.celebration,
    ),
    _Slide(
      title: 'Discover Verified Vendors',
      body: 'Photographers, DJs, caterers, decorators — all verified, rated, and reviewed by real customers.',
      gradient: [Color(0xFF1D4ED8), AppColors.violet],
      shape: _SlideShape.discover,
    ),
    _Slide(
      title: 'Compare & Choose Smartly',
      body: 'Compare up to 3 vendors side-by-side on price, rating, and availability before you decide.',
      gradient: [AppColors.violet, Color(0xFF0EA5E9)],
      shape: _SlideShape.compare,
    ),
    _Slide(
      title: 'Chat & Connect Directly',
      body: 'Message vendors, share photos, discuss requirements — and pay them directly with no platform fees.',
      gradient: [Color(0xFF059669), AppColors.violet],
      shape: _SlideShape.connect,
    ),
    _Slide(
      title: 'All Tools You Need',
      body: 'Event checklist, budget estimator, guest invite — everything to make your event perfect.',
      gradient: [AppColors.violetDeep, Color(0xFFBE185D)],
      shape: _SlideShape.tools,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    .map((c) => c.withValues(alpha: isDark ? 0.18 : 0.1))
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

                // Progress indicator (top)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: LinearProgressIndicator(
                    value: (_page + 1) / _slides.length,
                    backgroundColor: AppColors.violetMid.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation(
                        _slides[_page].gradient.first),
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(2),
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
                            _Illustration(
                              shape: slide.shape,
                              gradient: slide.gradient,
                              size: size.width * 0.7,
                            )
                                .animate(key: ValueKey(i))
                                .scale(
                                    duration: 600.ms,
                                    curve: Curves.elasticOut)
                                .fadeIn(),
                            const SizedBox(height: 40),

                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
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

enum _SlideShape { celebration, discover, compare, connect, tools }

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

// ── Illustrations ─────────────────────────────────────────────────────────────

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
      height: size * 0.82,
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
      case _SlideShape.discover:
        _paintDiscover(canvas, size, g);
      case _SlideShape.compare:
        _paintCompare(canvas, size, g);
      case _SlideShape.connect:
        _paintConnect(canvas, size, g);
      case _SlideShape.tools:
        _paintTools(canvas, size, g);
    }
  }

  // ── Slide 1: Celebration ─────────────────────────────────────────────────
  void _paintCelebration(Canvas canvas, Size s, LinearGradient g) {
    final paint = Paint()..shader = g.createShader(Offset.zero & s);
    canvas.drawCircle(Offset(s.width / 2, s.height / 2), s.width * 0.3, paint);

    final ringPaint = Paint()
      ..shader = g.createShader(Offset.zero & s)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(s.width / 2, s.height / 2), s.width * 0.38, ringPaint);
    canvas.drawCircle(Offset(s.width / 2, s.height / 2), s.width * 0.46, ringPaint..strokeWidth = 1.5);

    final dotPaint = Paint()..color = gradient.last.withValues(alpha: 0.7);
    for (var i = 0; i < 8; i++) {
      final angle = (i / 8) * 3.14159 * 2;
      final r = s.width * 0.46;
      canvas.drawCircle(Offset(s.width / 2 + r * _cos(angle), s.height / 2 + r * _sin(angle)), 6, dotPaint);
    }

    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    _drawStar(canvas, Offset(s.width * 0.18, s.height * 0.2), 16, starPaint);
    _drawStar(canvas, Offset(s.width * 0.82, s.height * 0.15), 12, starPaint);
    _drawStar(canvas, Offset(s.width * 0.75, s.height * 0.78), 10, starPaint);
    _drawStar(canvas, Offset(s.width * 0.15, s.height * 0.75), 14, starPaint);

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

  // ── Slide 2: Discover (search + cards) ──────────────────────────────────
  void _paintDiscover(Canvas canvas, Size s, LinearGradient g) {
    final paint = Paint()..shader = g.createShader(Offset.zero & s);

    // Background circle
    canvas.drawCircle(Offset(s.width / 2, s.height * 0.42), s.width * 0.34, paint);

    // Vendor cards (3 small cards fanning out)
    final cardPaint = Paint()..color = Colors.white.withValues(alpha: 0.15);
    final cardStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var i = 0; i < 3; i++) {
      final dx = (i - 1) * s.width * 0.22;
      final dy = i == 1 ? 0.0 : s.height * 0.06;
      final rr = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(s.width / 2 + dx, s.height * 0.42 + dy), width: s.width * 0.26, height: s.height * 0.36),
        const Radius.circular(14),
      );
      canvas.drawRRect(rr, cardPaint);
      canvas.drawRRect(rr, cardStroke);
      // Star inside each card
      _drawStar(canvas, Offset(s.width / 2 + dx, s.height * 0.38 + dy), 8,
          Paint()..color = Colors.white.withValues(alpha: 0.9));
    }

    // Verified shield
    final shieldPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    _drawShield(canvas, Offset(s.width / 2, s.height * 0.42), s.width * 0.15, shieldPaint);

    // Floating stars
    final dimStar = Paint()..color = gradient.first.withValues(alpha: 0.5);
    _drawStar(canvas, Offset(s.width * 0.1, s.height * 0.15), 10, dimStar);
    _drawStar(canvas, Offset(s.width * 0.88, s.height * 0.2), 12, dimStar);
    _drawStar(canvas, Offset(s.width * 0.15, s.height * 0.8), 8, dimStar);
    _drawStar(canvas, Offset(s.width * 0.85, s.height * 0.75), 10, dimStar);
  }

  // ── Slide 3: Compare ─────────────────────────────────────────────────────
  void _paintCompare(Canvas canvas, Size s, LinearGradient g) {
    final paint = Paint()..shader = g.createShader(Offset.zero & s);

    // Two comparison cards side by side
    final leftCard = RRect.fromRectAndRadius(
      Rect.fromLTWH(s.width * 0.06, s.height * 0.12, s.width * 0.38, s.height * 0.65),
      const Radius.circular(18),
    );
    final rightCard = RRect.fromRectAndRadius(
      Rect.fromLTWH(s.width * 0.56, s.height * 0.12, s.width * 0.38, s.height * 0.65),
      const Radius.circular(18),
    );
    canvas.drawRRect(leftCard, paint);
    canvas.drawRRect(rightCard, paint);

    // VS badge in middle
    final vsBg = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(s.width / 2, s.height * 0.44), 22, vsBg);
    final vsText = TextPainter(
      text: TextSpan(
        text: 'VS',
        style: TextStyle(
          color: gradient.first,
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    vsText.paint(canvas, Offset(s.width / 2 - vsText.width / 2, s.height * 0.44 - vsText.height / 2));

    // Rating bars in each card
    final barPaint = Paint()..color = Colors.white.withValues(alpha: 0.7);
    for (var i = 0; i < 3; i++) {
      final y = s.height * (0.35 + i * 0.14);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(s.width * 0.1, y, s.width * 0.28, 8), const Radius.circular(4)),
        barPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(s.width * 0.6, y, s.width * (0.15 + i * 0.07), 8), const Radius.circular(4)),
        barPaint,
      );
    }

    // Stars on cards
    _drawStar(canvas, Offset(s.width * 0.25, s.height * 0.25), 14, Paint()..color = Colors.white.withValues(alpha: 0.9));
    _drawStar(canvas, Offset(s.width * 0.75, s.height * 0.25), 14, Paint()..color = Colors.white.withValues(alpha: 0.9));

    // Bottom check mark on left card (winner)
    final checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final checkPath = Path();
    checkPath.moveTo(s.width * 0.15, s.height * 0.68);
    checkPath.lineTo(s.width * 0.22, s.height * 0.74);
    checkPath.lineTo(s.width * 0.35, s.height * 0.62);
    canvas.drawPath(checkPath, checkPaint);
  }

  // ── Slide 4: Connect directly ─────────────────────────────────────────────
  void _paintConnect(Canvas canvas, Size s, LinearGradient g) {
    final paint = Paint()..shader = g.createShader(Offset.zero & s);

    // Two circles (user + vendor)
    canvas.drawCircle(Offset(s.width * 0.25, s.height * 0.42), s.width * 0.2, paint);
    canvas.drawCircle(Offset(s.width * 0.75, s.height * 0.42), s.width * 0.2, paint);

    // Person silhouettes
    final personPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawCircle(Offset(s.width * 0.25, s.height * 0.34), 12, personPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(s.width * 0.25, s.height * 0.48), width: 28, height: 20), personPaint);
    canvas.drawCircle(Offset(s.width * 0.75, s.height * 0.34), 12, personPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(s.width * 0.75, s.height * 0.48), width: 28, height: 20), personPaint);

    // Connection line with chat bubbles
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(s.width * 0.38, s.height * 0.42), Offset(s.width * 0.62, s.height * 0.42), linePaint);

    // Chat bubble (above line)
    final bubblePaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(s.width / 2, s.height * 0.28), width: s.width * 0.28, height: 30),
        const Radius.circular(12),
      ),
      bubblePaint,
    );
    // Message dots
    final dotPaint = Paint()..color = gradient.first;
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(s.width / 2 - 10 + i * 10.0, s.height * 0.28), 3, dotPaint);
    }

    // "Free" badge
    final freeBadge = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(s.width / 2, s.height * 0.7), width: 80, height: 30),
        const Radius.circular(15),
      ),
      freeBadge,
    );
    final freeText = TextPainter(
      text: TextSpan(
        text: '100% FREE',
        style: TextStyle(color: gradient.first, fontWeight: FontWeight.w800, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    freeText.paint(canvas, Offset(s.width / 2 - freeText.width / 2, s.height * 0.7 - freeText.height / 2));

    // Floating stars
    _drawStar(canvas, Offset(s.width * 0.08, s.height * 0.2), 10, Paint()..color = gradient.last.withValues(alpha: 0.5));
    _drawStar(canvas, Offset(s.width * 0.92, s.height * 0.18), 8, Paint()..color = gradient.last.withValues(alpha: 0.5));
  }

  // ── Slide 5: Tools ────────────────────────────────────────────────────────
  void _paintTools(Canvas canvas, Size s, LinearGradient g) {
    final paint = Paint()..shader = g.createShader(Offset.zero & s);

    // Central hexagon (tools hub)
    _drawHexagon(canvas, Offset(s.width / 2, s.height * 0.44), s.width * 0.26, paint);

    // 4 tool icons around hexagon
    final iconPositions = [
      Offset(s.width * 0.2, s.height * 0.2),
      Offset(s.width * 0.8, s.height * 0.2),
      Offset(s.width * 0.15, s.height * 0.68),
      Offset(s.width * 0.85, s.height * 0.68),
    ];
    final iconPaint = Paint()..shader = g.createShader(Offset.zero & s);
    final connectPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final pos in iconPositions) {
      canvas.drawLine(pos, Offset(s.width / 2, s.height * 0.44), connectPaint);
      canvas.drawCircle(pos, s.width * 0.1, iconPaint);
      canvas.drawCircle(pos, s.width * 0.1, Paint()..color = Colors.white.withValues(alpha: 0.15));
    }

    // Checklist lines in top-left
    final listPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = s.height * 0.17 + i * 8.0;
      // Check mark
      if (i < 2) {
        final chk = Path();
        chk.moveTo(iconPositions[0].dx - 12, y);
        chk.lineTo(iconPositions[0].dx - 8, y + 4);
        chk.lineTo(iconPositions[0].dx - 2, y - 3);
        canvas.drawPath(chk, listPaint);
      }
      canvas.drawLine(Offset(iconPositions[0].dx - 0.0, y), Offset(iconPositions[0].dx + 10, y), listPaint);
    }

    // Budget rupee symbol in top-right
    _drawRupee(canvas, iconPositions[1], 12, Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    // Guest people in bottom-left
    final pPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawCircle(Offset(iconPositions[2].dx - 6, iconPositions[2].dy - 8), 5, pPaint);
    canvas.drawCircle(Offset(iconPositions[2].dx + 6, iconPositions[2].dy - 8), 5, pPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(iconPositions[2].dx - 6, iconPositions[2].dy + 2), width: 12, height: 8), pPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(iconPositions[2].dx + 6, iconPositions[2].dy + 2), width: 12, height: 8), pPaint);

    // Star in center hexagon
    _drawStar(canvas, Offset(s.width / 2, s.height * 0.44), 18,
        Paint()..color = Colors.white.withValues(alpha: 0.9));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  double _cos(double a) {
    double x = a % (2 * 3.14159265358979);
    return 1 - (x * x) / 2 + (x * x * x * x) / 24;
  }

  double _sin(double a) {
    double x = a % (2 * 3.14159265358979);
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }

  void _drawStar(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * 3.14159 / 180;
      final innerAngle = ((i * 72 + 36) - 90) * 3.14159 / 180;
      final outer = Offset(center.dx + r * _cos(outerAngle), center.dy + r * _sin(outerAngle));
      final inner = Offset(center.dx + r * 0.45 * _cos(innerAngle), center.dy + r * 0.45 * _sin(innerAngle));
      if (i == 0) { path.moveTo(outer.dx, outer.dy); } else { path.lineTo(outer.dx, outer.dy); }
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawShield(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - r);
    path.lineTo(center.dx + r * 0.9, center.dy - r * 0.5);
    path.lineTo(center.dx + r * 0.9, center.dy + r * 0.2);
    path.quadraticBezierTo(center.dx + r * 0.9, center.dy + r, center.dx, center.dy + r);
    path.quadraticBezierTo(center.dx - r * 0.9, center.dy + r, center.dx - r * 0.9, center.dy + r * 0.2);
    path.lineTo(center.dx - r * 0.9, center.dy - r * 0.5);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHexagon(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * 3.14159 / 180;
      final x = center.dx + r * _cos(angle);
      final y = center.dy + r * _sin(angle);
      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
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
    path.quadraticBezierTo(center.dx + size * 0.5, center.dy - size * 0.6, center.dx + size * 0.5, center.dy - size * 0.4);
    path.quadraticBezierTo(center.dx + size * 0.5, center.dy - size * 0.1, center.dx - size * 0.5, center.dy - size * 0.2);
    path.moveTo(center.dx - size * 0.3, center.dy - size * 0.15);
    path.lineTo(center.dx + size * 0.4, center.dy + size * 0.7);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _IllustrationPainter old) =>
      old.shape != shape || old.gradient != gradient;
}
