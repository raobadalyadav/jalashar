import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';

/// Reusable empty state widget.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.ivory,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.deepMaroon),
            ),
            const SizedBox(height: 20),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Something went wrong',
      subtitle: error.toString(),
      action: onRetry != null
          ? FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            )
          : null,
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.height = 100});
  final double height;
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(children: [
        Expanded(
          child: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class AppSnack {
  static void success(BuildContext c, String msg) =>
      _show(c, msg, AppColors.success, Icons.check_circle);
  static void error(BuildContext c, String msg) =>
      _show(c, msg, AppColors.danger, Icons.error);
  static void info(BuildContext c, String msg) =>
      _show(c, msg, AppColors.saffron, Icons.info);

  static void _show(BuildContext c, String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      content: Row(children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
      ]),
    ));
  }
}
