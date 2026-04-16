import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/content_repositories.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/widgets.dart';
import '../../core/utils/formatters.dart';

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refs = ref.watch(myReferralsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Refer & Earn')),
      body: refs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e),
        data: (list) {
          final code = list.isNotEmpty ? list.first.code : null;
          final earned = list
              .where((r) => r.status == 'completed')
              .fold<double>(0, (s, r) => s + r.rewardAmount);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [AppColors.violet, AppColors.violetDeep],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Invite friends, earn ₹200',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text('Get ₹200 credit for every successful booking.',
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 20),
                    if (code == null)
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.violetDeep,
                        ),
                        onPressed: () async {
                          try {
                            await ref
                                .read(referralRepoProvider)
                                .generateMyCode();
                            ref.invalidate(myReferralsProvider);
                          } catch (e) {
                            if (context.mounted) {
                              AppSnack.error(context, e.toString());
                            }
                          }
                        },
                        child: const Text('Generate My Code'),
                      )
                    else
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: code));
                          AppSnack.success(context, 'Code copied!');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(children: [
                            Expanded(
                              child: Text(code,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2,
                                      color: AppColors.violet)),
                            ),
                            const Icon(Icons.copy, color: AppColors.violet),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        Text('${list.length}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.violet)),
                        const Text('Total Referrals'),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        Text(Fmt.currency(earned),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success)),
                        const Text('Earned'),
                      ]),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              const SectionHeader(title: 'How it works'),
              _step('1', 'Share your code', 'Send it to friends via WhatsApp or social media'),
              _step('2', 'They sign up', "Your friend creates an account using your code"),
              _step('3', 'You both earn', 'Get ₹200 after their first successful booking'),
            ],
          );
        },
      ),
    );
  }

  Widget _step(String n, String title, String desc) => ListTile(
        leading: Builder(builder: (ctx) => CircleAvatar(
          backgroundColor: ctx.softSurface,
          child: Text(n,
              style: TextStyle(
                  color: ctx.isDark ? Colors.white : AppColors.violetDeep, fontWeight: FontWeight.w700)),
        )),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(desc),
      );
}
