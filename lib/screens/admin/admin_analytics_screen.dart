import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../utils/analytics.dart';
import '../../utils/formatters.dart';
import '../../widgets/stat_card.dart';

/// The admin's deeper reporting screen, filtered by a period selector —
/// the Dashboard tab stays a live, all-time operations snapshot; this tab
/// answers "how many/how much, broken down daily/weekly/monthly/yearly."
class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  ReportPeriod _period = ReportPeriod.thisWeek;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final period = _period;

    final partnerCounts = appState.orderCountByPartner(period).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final driverStats = appState.driverPickupStats(period).entries.toList()
      ..sort((a, b) => b.value.pickupCount.compareTo(a.value.pickupCount));
    final avgPickup = appState.averagePickupDuration(period);
    final slowPickups = appState.slowPickupCount(period);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in ReportPeriod.values)
                ChoiceChip(
                  label: Text(p.label),
                  selected: _period == p,
                  onSelected: (_) => setState(() => _period = p),
                ),
            ],
          ),
          const SizedBox(height: 20),

          Text('Order funnel', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _StatRow(children: [
            StatCard(label: 'Received', value: '${appState.receivedCountFor(period)}', icon: Icons.inbox_outlined),
            StatCard(
              label: 'Picked up',
              value: '${appState.pickedUpCountFor(period)}',
              icon: Icons.local_shipping_outlined,
            ),
            StatCard(
              label: 'Delivered',
              value: '${appState.deliveredCountFor(period)}',
              icon: Icons.check_circle_outline,
            ),
          ]),

          const SizedBox(height: 20),
          Text('Revenue', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _StatRow(children: [
            StatCard(
              label: 'Revenue (GMV)',
              value: formatCurrency(appState.revenueFor(period)),
              icon: Icons.payments_outlined,
            ),
            StatCard(
              label: 'Platform commission',
              value: formatCurrency(appState.commissionFor(period)),
              icon: Icons.account_balance_wallet_outlined,
            ),
          ]),

          const SizedBox(height: 20),
          Text('Cancellations', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _StatRow(children: [
            StatCard(
              label: 'Cancelled orders',
              value: '${appState.cancelledCountFor(period)}',
              icon: Icons.cancel_outlined,
            ),
            StatCard(
              label: 'Cancelled — taking too long',
              value: '${appState.cancelledDueToDelayCountFor(period)}',
              icon: Icons.timer_off_outlined,
            ),
          ]),

          const SizedBox(height: 20),
          Text('Driver pickup time', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Measured from when a driver is assigned a pickup to when they mark it picked up. '
            'A pickup over ${formatDuration(AppState.kSlowPickupThreshold)} counts as slow.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          _StatRow(children: [
            StatCard(
              label: 'Average pickup time',
              value: avgPickup == null ? '—' : formatDuration(avgPickup),
              icon: Icons.timer_outlined,
            ),
            StatCard(label: 'Slow pickups', value: '$slowPickups', icon: Icons.warning_amber_outlined),
          ]),
          const SizedBox(height: 8),
          if (driverStats.isEmpty)
            const Padding(padding: EdgeInsets.all(8), child: Text('No completed pickups in this period.'))
          else
            for (final entry in driverStats)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.two_wheeler_outlined),
                  title: Text(appState.driverById(entry.key)?.name ?? entry.key),
                  subtitle: Text('${entry.value.pickupCount} pickup${entry.value.pickupCount == 1 ? '' : 's'}'
                      ' • avg ${formatDuration(entry.value.average)}'),
                  trailing: entry.value.slowCount == 0
                      ? null
                      : Chip(
                          label: Text('${entry.value.slowCount} slow'),
                          backgroundColor: Colors.red.withOpacity(0.12),
                          labelStyle: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                ),
              ),

          const SizedBox(height: 20),
          Text('Partner performance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (partnerCounts.isEmpty)
            const Padding(padding: EdgeInsets.all(8), child: Text('No orders in this period.'))
          else
            for (final entry in partnerCounts)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.storefront_outlined),
                  title: Text(appState.partnerById(entry.key).name),
                  trailing: Text(
                    '${entry.value} order${entry.value == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// Lays StatCards out in an evenly-spaced row that still wraps sensibly on
/// a narrow phone screen, instead of a fixed-column GridView.
class _StatRow extends StatelessWidget {
  const _StatRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: SizedBox(height: 100, child: children[i])),
        ],
      ],
    );
  }
}
