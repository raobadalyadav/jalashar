import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/content_repositories.dart';
import '../../core/ui/widgets.dart';

class FaqScreen extends ConsumerWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faqs = ref.watch(faqsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Help & FAQ')),
      body: faqs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e),
        data: (list) {
          final grouped = <String, List>{};
          for (final f in list) {
            grouped.putIfAbsent(f.category ?? 'General', () => []).add(f);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final entry in grouped.entries) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(entry.key,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                ...entry.value.map((f) => Card(
                      child: ExpansionTile(
                        title: Text(f.question),
                        childrenPadding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(f.answer),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }
}
