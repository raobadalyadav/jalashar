import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

class BudgetEstimatorScreen extends StatefulWidget {
  const BudgetEstimatorScreen({super.key});

  @override
  State<BudgetEstimatorScreen> createState() => _BudgetEstimatorScreenState();
}

class _BudgetEstimatorScreenState extends State<BudgetEstimatorScreen> {
  String _eventType = 'Wedding';
  double _guests = 100;
  final Set<String> _selectedCategories = {
    'Photography', 'Catering', 'Decoration'
  };

  static const _eventTypes = [
    'Wedding', 'Engagement', 'Birthday', 'Corporate',
    'Anniversary', 'Festival',
  ];

  // (category, icon, baseMin, baseMax, perGuestMin, perGuestMax, note)
  static const _categoryData = [
    ('Photography', Icons.camera_alt_outlined, 15000, 80000, 0, 0,
        'Full day candid + traditional'),
    ('Videography', Icons.videocam_outlined, 20000, 100000, 0, 0,
        'Cinematic highlight reel'),
    ('Catering', Icons.restaurant_outlined, 0, 0, 300, 1200,
        'Per plate (veg / non-veg)'),
    ('Decoration', Icons.celebration_outlined, 15000, 200000, 0, 0,
        'Floral + LED + stage setup'),
    ('DJ / Sound', Icons.music_note_outlined, 8000, 40000, 0, 0,
        'System + DJ for 6 hours'),
    ('Band', Icons.queue_music_outlined, 15000, 80000, 0, 0,
        'Live band performance'),
    ('Makeup', Icons.brush_outlined, 5000, 35000, 0, 0,
        'Bridal / party makeup'),
    ('Mehendi', Icons.pan_tool_outlined, 3000, 20000, 0, 0,
        'Bridal mehendi full hands'),
    ('Florist', Icons.local_florist_outlined, 8000, 60000, 0, 0,
        'Bouquet, garland, stage flowers'),
    ('Pandit / Ceremony', Icons.temple_hindu_outlined, 3000, 15000, 0, 0,
        'Pooja / vivah ceremony'),
    ('Choreographer', Icons.directions_run_outlined, 5000, 30000, 0, 0,
        'Dance performance rehearsal'),
    ('Invitation Cards', Icons.mail_outline_rounded, 2000, 20000, 5, 30,
        'Printed + digital invites'),
  ];

  List<(String, int, int)> _getEstimates() {
    return _categoryData
        .where((c) => _selectedCategories.contains(c.$1))
        .map((c) {
          int min = c.$3;
          int max = c.$4;
          if (c.$5 > 0) {
            min += (c.$5 * _guests).toInt();
            max += (c.$6 * _guests).toInt();
          }
          return (c.$1, min, max);
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final estimates = _getEstimates();
    final totalMin = estimates.fold(0, (s, e) => s + e.$2);
    final totalMax = estimates.fold(0, (s, e) => s + e.$3);

    return Scaffold(
      appBar: AppBar(title: const Text('Budget Estimator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Event type
          Text('Event Type',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _eventTypes
                .map((t) => ChoiceChip(
                      label: Text(t),
                      selected: _eventType == t,
                      selectedColor: AppColors.violet.withValues(alpha: 0.15),
                      onSelected: (v) {
                        if (v) setState(() => _eventType = t);
                      },
                    ))
                .toList(),
          ).animate().fadeIn(),

          const SizedBox(height: 24),

          // Guest count
          Row(children: [
            Text('Guest Count',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.violet.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_guests.toInt()} guests',
                style: const TextStyle(
                    color: AppColors.violet, fontWeight: FontWeight.w700),
              ),
            ),
          ]),
          Slider(
            value: _guests,
            min: 10,
            max: 1000,
            divisions: 99,
            onChanged: (v) => setState(() => _guests = v),
            activeColor: AppColors.violet,
          ).animate().fadeIn(delay: 80.ms),

          const SizedBox(height: 24),

          // Categories to include
          Text('Services to Include',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categoryData
                .map((c) => FilterChip(
                      avatar: Icon(c.$2, size: 16),
                      label: Text(c.$1),
                      selected: _selectedCategories.contains(c.$1),
                      selectedColor:
                          AppColors.violet.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.violet,
                      onSelected: (v) => setState(() {
                        if (v) {
                          _selectedCategories.add(c.$1);
                        } else {
                          _selectedCategories.remove(c.$1);
                        }
                      }),
                    ))
                .toList(),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 28),

          // Total banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.violetDeep, AppColors.violet],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('Estimated Total Budget',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  '${Fmt.currency(totalMin)} – ${Fmt.currency(totalMax)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'For $_eventType · ${_guests.toInt()} guests',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 120.ms).scale(begin: const Offset(0.95, 0.95)),

          const SizedBox(height: 20),

          // Breakdown
          if (estimates.isNotEmpty) ...[
            Text('Cost Breakdown',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...estimates.asMap().entries.map((entry) {
              final (name, min, max) = entry.value;
              final note = _categoryData
                  .firstWhere((c) => c.$1 == name)
                  .$7;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          Text(note,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.slate)),
                        ],
                      ),
                    ),
                    Text(
                      min == max
                          ? Fmt.currency(min)
                          : '${Fmt.currency(min)}–${Fmt.currency(max)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.violet),
                    ),
                  ]),
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 140 + entry.key * 40));
            }),
          ],

          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.softSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.violet, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'These are estimated ranges based on average market rates. Actual prices vary by vendor, city, and season. Platform booking is 100% free.',
                  style: TextStyle(fontSize: 11, color: AppColors.slate),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
