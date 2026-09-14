import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../models/address.dart';
import 'add_address_screen.dart';

/// "Locate yourself, or use a saved address" — the pickup/delivery address
/// picker on the schedule screen, in the spirit of Talabat's address step:
///
///   - **Use my current location**: a one-tap, one-off pickup point from
///     the device's real GPS (see `DeviceLocationService`) — not saved to
///     the address book, just used for this order.
///   - **Saved addresses**: the customer's address book.
///   - **Add a new address**: opens [AddAddressScreen] (pin-drop on a
///     placeholder map, or current-location-assisted) and saves it for
///     future orders too.
class AddressSelector extends StatefulWidget {
  const AddressSelector({super.key, required this.selected, required this.onChanged});

  final Address? selected;
  final ValueChanged<Address> onChanged;

  @override
  State<AddressSelector> createState() => _AddressSelectorState();
}

class _AddressSelectorState extends State<AddressSelector> {
  bool _locating = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final addresses = appState.currentCustomer.addresses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: _locating
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary),
          title: const Text('Use my current location'),
          subtitle: widget.selected?.id.startsWith('current-') ?? false
              ? Text(
                  '${widget.selected!.location.lat.toStringAsFixed(4)}, '
                  '${widget.selected!.location.lng.toStringAsFixed(4)}',
                )
              : null,
          selected: widget.selected?.id.startsWith('current-') ?? false,
          onTap: _locating ? null : () => _useCurrentLocation(appState),
        ),
        for (final address in addresses)
          RadioListTile<Address>(
            contentPadding: EdgeInsets.zero,
            value: address,
            groupValue: widget.selected,
            title: Text(address.label),
            subtitle: Text('${address.line1}, ${address.city}'),
            onChanged: (v) {
              if (v != null) widget.onChanged(v);
            },
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.add_location_alt_outlined),
          title: const Text('Add a new address'),
          onTap: () async {
            final added = await Navigator.of(context).push<Address>(
              MaterialPageRoute(builder: (_) => const AddAddressScreen()),
            );
            if (added != null) widget.onChanged(added);
          },
        ),
      ],
    );
  }

  Future<void> _useCurrentLocation(AppState appState) async {
    setState(() => _locating = true);
    final point = await appState.deviceLocationService.getCurrentLocation();
    if (!mounted) return;
    setState(() => _locating = false);
    if (point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't get your location. Check location permission, or pick a saved address instead."),
        ),
      );
      return;
    }
    widget.onChanged(
      Address(
        id: 'current-${DateTime.now().millisecondsSinceEpoch}',
        label: 'Current location',
        line1: 'Detected via device GPS',
        city: appState.currentCustomer.addresses.isNotEmpty ? appState.currentCustomer.addresses.first.city : '',
        location: point,
      ),
    );
  }
}
