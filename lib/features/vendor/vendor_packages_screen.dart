import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

const _eventTypes = [
  'Wedding',
  'Birthday',
  'Corporate',
  'Engagement',
  'Anniversary',
  'Festival',
  'Other',
];

class VendorPackagesScreen extends ConsumerWidget {
  const VendorPackagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packagesAsync = ref.watch(myVendorPackagesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Packages & Pricing')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPackageDialog(context, ref, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Package'),
        backgroundColor: AppColors.violet,
        foregroundColor: Colors.white,
      ),
      body: packagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (packages) {
          if (packages.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.violet, AppColors.violetDeep],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.inventory_2_outlined,
                          color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text('No packages yet',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Add packages to show clients what you offer and your pricing for each event type.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.slate),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _showPackageDialog(context, ref, null),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create First Package'),
                    ),
                  ],
                ),
              ),
            );
          }

          final grouped = <String, List<VendorPackage>>{};
          for (final p in packages) {
            final key = p.eventType ?? 'General';
            grouped.putIfAbsent(key, () => []).add(p);
          }

          return RefreshIndicator(
            color: AppColors.violet,
            onRefresh: () async => ref.invalidate(myVendorPackagesProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                for (final entry in grouped.entries) ...[
                  _EventTypeHeader(eventType: entry.key),
                  const SizedBox(height: 8),
                  ...entry.value.asMap().entries.map(
                    (e) => _PackageCard(
                      package: e.value,
                      index: e.key,
                      onEdit: () => _showPackageDialog(context, ref, e.value),
                      onDelete: () => _confirmDelete(context, ref, e.value),
                    ).animate().fadeIn(delay: Duration(milliseconds: e.key * 60)),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showPackageDialog(
      BuildContext context, WidgetRef ref, VendorPackage? pkg) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PackageFormSheet(
        existing: pkg,
        onSaved: () => ref.invalidate(myVendorPackagesProvider),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, VendorPackage pkg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Package?'),
        content: Text('Remove "${pkg.name}" from your packages?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(vendorPackageRepoProvider).delete(pkg.id);
    ref.invalidate(myVendorPackagesProvider);
  }
}

class _EventTypeHeader extends StatelessWidget {
  const _EventTypeHeader({required this.eventType});
  final String eventType;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.violet, AppColors.violetDeep],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(eventType,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
      ),
      const SizedBox(width: 8),
      Expanded(child: Divider(color: AppColors.violetMid)),
    ]);
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });
  final VendorPackage package;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(package.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      if (package.durationHours != null)
                        Text('${package.durationHours}h coverage',
                            style: TextStyle(
                                color: AppColors.slate, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(Fmt.currency(package.price),
                        style: const TextStyle(
                            color: AppColors.violet,
                            fontWeight: FontWeight.w800,
                            fontSize: 18)),
                    const Text('onwards',
                        style:
                            TextStyle(fontSize: 10, color: AppColors.slate)),
                  ],
                ),
              ],
            ),
            if (package.features.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: package.features
                    .map((f) => Builder(builder: (ctx) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: ctx.softSurface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(f,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.violet)),
                        )))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageFormSheet extends ConsumerStatefulWidget {
  const _PackageFormSheet({this.existing, required this.onSaved});
  final VendorPackage? existing;
  final VoidCallback onSaved;

  @override
  ConsumerState<_PackageFormSheet> createState() => _PackageFormSheetState();
}

class _PackageFormSheetState extends ConsumerState<_PackageFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _duration = TextEditingController();
  final _featureInput = TextEditingController();
  String? _selectedEventType;
  final List<String> _features = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final pkg = widget.existing;
    if (pkg != null) {
      _name.text = pkg.name;
      _price.text = pkg.price.toStringAsFixed(0);
      _duration.text = pkg.durationHours?.toString() ?? '';
      _selectedEventType = pkg.eventType;
      _features.addAll(pkg.features);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _duration.dispose();
    _featureInput.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(vendorPackageRepoProvider);
    final vendorId = await repo.myVendorId();
    if (vendorId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vendor profile not found')));
      }
      return;
    }

    setState(() => _saving = true);
    try {
      await repo.upsert(
            id: widget.existing?.id,
            vendorId: vendorId,
            name: _name.text.trim(),
            price: double.parse(_price.text),
            durationHours: int.tryParse(_duration.text),
            features: _features,
            eventType: _selectedEventType,
          );
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addFeature() {
    final text = _featureInput.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _features.add(text);
      _featureInput.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Text(isEdit ? 'Edit Package' : 'New Package',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ]),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Package Name *',
                        hintText: 'e.g. Full Day Wedding Coverage',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedEventType,
                      decoration: const InputDecoration(
                        labelText: 'Event Type',
                        prefixIcon: Icon(Icons.event_outlined),
                      ),
                      items: _eventTypes
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedEventType = v),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (₹) *',
                        prefixIcon: Icon(Icons.currency_rupee_rounded),
                        hintText: 'e.g. 25000',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Enter valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _duration,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration (hours)',
                        prefixIcon: Icon(Icons.schedule_outlined),
                        hintText: 'e.g. 8',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('What\'s Included',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _featureInput,
                          decoration: const InputDecoration(
                            hintText: 'e.g. 500 edited photos',
                            prefixIcon: Icon(Icons.add_circle_outline_rounded),
                          ),
                          onSubmitted: (_) => _addFeature(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _addFeature,
                        style: FilledButton.styleFrom(
                            minimumSize: const Size(50, 50)),
                        child: const Icon(Icons.add_rounded),
                      ),
                    ]),
                    if (_features.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _features
                            .asMap()
                            .entries
                            .map((e) => Chip(
                                  label: Text(e.value,
                                      style: const TextStyle(fontSize: 12)),
                                  deleteIcon: const Icon(Icons.close, size: 14),
                                  onDeleted: () => setState(
                                      () => _features.removeAt(e.key)),
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: AppColors.violet,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(isEdit ? 'Update Package' : 'Save Package',
                              style: const TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
