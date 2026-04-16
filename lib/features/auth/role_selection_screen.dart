import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/user_role.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});
  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  final _name = TextEditingController();
  UserRole _role = UserRole.client;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('auth.choose_role'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              decoration: InputDecoration(hintText: 'auth.full_name'.tr()),
            ),
            const SizedBox(height: 24),
            _RoleCard(
              title: 'auth.role_client'.tr(),
              subtitle: 'auth.role_client_desc'.tr(),
              icon: Icons.celebration_outlined,
              selected: _role == UserRole.client,
              onTap: () => setState(() => _role = UserRole.client),
            ),
            const SizedBox(height: 12),
            _RoleCard(
              title: 'auth.role_vendor'.tr(),
              subtitle: 'auth.role_vendor_desc'.tr(),
              icon: Icons.storefront_outlined,
              selected: _role == UserRole.vendor,
              onTap: () => setState(() => _role = UserRole.vendor),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      try {
                        await ref
                            .read(authControllerProvider)
                            .completeProfile(name: _name.text.trim(), role: _role);
                        ref.invalidate(currentUserProvider);
                        if (mounted) context.go('/splash');
                      } finally {
                        if (mounted) setState(() => _loading = false);
                      }
                    },
              child: Text('common.continue'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String title, subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          color: selected ? scheme.primary.withValues(alpha: 0.08) : null,
        ),
        child: Row(children: [
          Icon(icon, size: 36, color: scheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (selected) Icon(Icons.check_circle, color: scheme.primary),
        ]),
      ),
    );
  }
}
