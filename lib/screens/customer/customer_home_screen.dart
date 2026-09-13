import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../widgets/partner_card.dart';
import 'partner_catalog_screen.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: const Text('LaundryGo'),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () => _showNotifications(context, appState),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Laundry partners near ${appState.customer.addresses.first.city}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final partner = appState.partners[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PartnerCard(
                    partner: partner,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PartnerCatalogScreen(partnerId: partner.id)),
                    ),
                  ),
                );
              },
              childCount: appState.partners.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  void _showNotifications(BuildContext context, AppState appState) {
    final feed = appState.notificationService.feedFor(appState.customer.id);
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          children: [
            Text('Notifications', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (feed.isEmpty) const Text('No notifications yet.'),
            for (final message in feed) ListTile(leading: const Icon(Icons.notifications), title: Text(message)),
          ],
        ),
      ),
    );
  }
}
