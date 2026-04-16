import 'package:flutter/material.dart';
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
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.saffron, AppColors.deepMaroon],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.celebration, color: Colors.white, size: 100),
                ),
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
                              color: AppColors.deepMaroon,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    if (service.planningDuration != null)
                      Chip(
                        avatar: const Icon(Icons.schedule,
                            size: 16, color: AppColors.deepMaroon),
                        label: Text(service.planningDuration!),
                        backgroundColor: AppColors.ivory,
                      ),
                  ]),
                  const SizedBox(height: 16),
                  if (service.description != null) ...[
                    Text(service.description!,
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 20),
                  ],
                  Text('What\'s Included',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  ...service.features.map((f) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: AppColors.ivory,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check,
                                size: 16, color: AppColors.success),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child:
                                  Text(f, style: Theme.of(context).textTheme.bodyMedium)),
                        ]),
                      )),
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
