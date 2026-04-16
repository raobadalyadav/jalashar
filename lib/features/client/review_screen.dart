import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/extra_repositories.dart';
import '../../core/theme/app_theme.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.bookingId, required this.vendorId});
  final String bookingId;
  final String vendorId;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _stars = 5;
  final _comment = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await ref.read(reviewRepoProvider).submit(
            bookingId: widget.bookingId,
            vendorId: widget.vendorId,
            stars: _stars,
            comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
          );
      ref.invalidate(vendorReviewsProvider(widget.vendorId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Review submitted')));
        context.pop();
      }
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
    return Scaffold(
      appBar: AppBar(title: const Text('Rate your experience')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _stars;
                return IconButton(
                  iconSize: 44,
                  onPressed: () => setState(() => _stars = i + 1),
                  icon: Icon(
                    filled ? Icons.star : Icons.star_border,
                    color: AppColors.gold,
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _comment,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Share your experience (optional)',
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? '...' : 'Submit Review'),
            ),
          ],
        ),
      ),
    );
  }
}
