import 'package:flutter/material.dart';

import '../models/user_models.dart';

class PartnerCard extends StatelessWidget {
  const PartnerCard({super.key, required this.partner, required this.onTap});

  final LaundryPartner partner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: partner.isOpen ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_laundry_service),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(partner.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${partner.area} • ${partner.catalog.length} services',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(partner.rating.toStringAsFixed(1), style: Theme.of(context).textTheme.bodySmall),
                        if (!partner.isOpen) ...[
                          const SizedBox(width: 10),
                          Text(
                            'Closed now',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
