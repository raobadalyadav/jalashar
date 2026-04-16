import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({super.key, required this.service});
  final ServicePackage service;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(service.name),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (service.imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: service.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                      ),
                    )
                  else
                    Container(
                      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                      child: const _ServiceIllustration(),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        Fmt.currency(service.basePrice),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.violet,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    if (service.planningDuration != null)
                      Chip(
                        avatar: const Icon(Icons.schedule,
                            size: 16, color: AppColors.violet),
                        label: Text(service.planningDuration!),
                        backgroundColor: context.softSurface,
                      ),
                  ]).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),
                  if (service.description != null) ...[
                    Text(service.description!,
                        style: Theme.of(context).textTheme.bodyLarge)
                        .animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 20),
                  ],
                  Text('What\'s Included',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700))
                      .animate().fadeIn(delay: 150.ms),
                  const SizedBox(height: 12),
                  ...service.features.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: context.softSurface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded,
                                size: 16, color: AppColors.success),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(e.value,
                                  style: Theme.of(context).textTheme.bodyMedium)),
                        ]),
                      ).animate().fadeIn(delay: Duration(milliseconds: 200 + e.key * 60))
                          .slideX(begin: -0.1)),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => context.push('/booking/new', extra: service),
            child: Text('Book Now · ${Fmt.currency(service.basePrice)}'),
          ),
        ),
      ),
    );
  }
}

class _ServiceIllustration extends StatelessWidget {
  const _ServiceIllustration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ServicePainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _ServicePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Decorative circles
    paint.color = Colors.white.withValues(alpha: 0.06);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.2), 80, paint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.8), 100, paint);

    paint.color = Colors.white.withValues(alpha: 0.08);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.15), 50, paint);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.85), 40, paint);

    // Central star/sparkle dots
    paint.color = Colors.white.withValues(alpha: 0.4);
    for (final pt in [
      Offset(size.width * 0.5, size.height * 0.35),
      Offset(size.width * 0.38, size.height * 0.55),
      Offset(size.width * 0.62, size.height * 0.55),
      Offset(size.width * 0.5, size.height * 0.7),
    ]) {
      canvas.drawCircle(pt, 5, paint);
    }

    paint.color = Colors.white.withValues(alpha: 0.25);
    for (final pt in [
      Offset(size.width * 0.25, size.height * 0.4),
      Offset(size.width * 0.75, size.height * 0.4),
      Offset(size.width * 0.5, size.height * 0.5),
    ]) {
      canvas.drawCircle(pt, 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
