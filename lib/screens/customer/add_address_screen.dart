import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../models/address.dart';
import '../../widgets/map_pin_picker.dart';

/// "Add a new address" — drop a pin on the map (or use the device's current
/// location to set one), then confirm the address details. Pushed from
/// [AddressSelector]; pops with the newly saved [Address] so the caller can
/// select it immediately.
class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController(text: 'Home');
  final _lineController = TextEditingController();
  final _cityController = TextEditingController(text: 'Muscat');

  // Central Muscat — the demo map's default pin until the customer taps
  // elsewhere or uses their current location.
  GeoPoint _pin = const GeoPoint(23.588, 58.407);
  bool _locating = false;

  @override
  void dispose() {
    _labelController.dispose();
    _lineController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add address')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            MapPinPicker(pin: _pin, onPinChanged: (p) => setState(() => _pin = p)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: _locating
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, size: 18),
                label: const Text('Use my current location'),
                onPressed: _locating ? null : _useCurrentLocation,
              ),
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _labelController,
                    decoration: const InputDecoration(
                      labelText: 'Label (e.g. Home, Office)',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lineController,
                    decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.home_outlined)),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city)),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(onPressed: _save, child: const Text('Save address')),
        ),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    final appState = context.read<AppState>();
    final point = await appState.deviceLocationService.getCurrentLocation();
    if (!mounted) return;
    setState(() => _locating = false);
    if (point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't get your location. Check location permission, or drop a pin on the map instead."),
        ),
      );
      return;
    }
    setState(() => _pin = point);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location detected — confirm the address details below.')),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final appState = context.read<AppState>();
    final address = Address(
      id: 'addr-${DateTime.now().millisecondsSinceEpoch}',
      label: _labelController.text.trim(),
      line1: _lineController.text.trim(),
      city: _cityController.text.trim(),
      location: _pin,
    );
    appState.addCustomerAddress(appState.currentCustomer.id, address);
    Navigator.of(context).pop(address);
  }
}
