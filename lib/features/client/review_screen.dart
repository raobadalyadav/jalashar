import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/data/extra_repositories.dart';
import '../../core/theme/app_theme.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen(
      {super.key, required this.bookingId, required this.vendorId});
  final String bookingId;
  final String vendorId;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _stars = 5;
  final _comment = TextEditingController();
  final List<File> _photos = [];
  bool _loading = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_photos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 5 photos allowed')));
      return;
    }
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file != null) setState(() => _photos.add(File(file.path)));
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final storage = ref.read(storageRepoProvider);
      final urls = <String>[];
      for (final f in _photos) {
        urls.add(await storage.uploadReviewPhoto(f));
      }
      await ref.read(reviewRepoProvider).submit(
            bookingId: widget.bookingId,
            vendorId: widget.vendorId,
            stars: _stars,
            comment:
                _comment.text.trim().isEmpty ? null : _comment.text.trim(),
            photos: urls,
          );
      ref.invalidate(vendorReviewsProvider(widget.vendorId));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Review submitted!')));
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Star selector
            Center(
              child: Column(
                children: [
                  Text(
                    _starLabel(_stars),
                    style: TextStyle(
                        color: AppColors.violet,
                        fontWeight: FontWeight.w700,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 8),
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
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Comment field
            TextField(
              controller: _comment,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Share your experience (optional)',
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 20),

            // Photo section
            Row(children: [
              const Text('Add Photos',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${_photos.length}/5',
                  style: const TextStyle(
                      color: AppColors.slate, fontSize: 12)),
            ]),
            const SizedBox(height: 10),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._photos.asMap().entries.map(
                        (e) => Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.only(right: 8),
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Image.file(e.value,
                                  fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 2,
                              right: 10,
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _photos.removeAt(e.key)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  if (_photos.length < 5)
                    GestureDetector(
                      onTap: _pickPhoto,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: context.softSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.violetMid,
                              style: BorderStyle.solid),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                color: AppColors.violet, size: 28),
                            SizedBox(height: 4),
                            Text('Add',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.violet)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }

  String _starLabel(int stars) => switch (stars) {
        1 => 'Terrible',
        2 => 'Bad',
        3 => 'Okay',
        4 => 'Good',
        _ => 'Excellent!',
      };
}
