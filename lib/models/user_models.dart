import 'address.dart';
import 'catalog.dart';

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.addresses,
  });

  final String id;
  final String name;
  final String phone;
  final List<Address> addresses;
}

/// A local laundromat/dry-cleaner onboarded to the marketplace. The
/// aggregator model means each partner keeps its own catalog/pricing and
/// pays the platform a [commissionRate] cut on every order.
class LaundryPartner {
  const LaundryPartner({
    required this.id,
    required this.name,
    required this.area,
    required this.location,
    required this.rating,
    required this.isOpen,
    required this.commissionRate,
    required this.catalog,
  });

  final String id;
  final String name;
  final String area;
  final GeoPoint location;
  final double rating;
  final bool isOpen;

  /// e.g. 0.20 == the platform takes 20% of every order's item subtotal.
  final double commissionRate;

  /// Mutable in place (prices are edited by the partner) while the list
  /// reference itself stays fixed.
  final List<CatalogItem> catalog;
}

class Driver {
  Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicle,
    required this.rating,
    required this.isAvailable,
    required this.location,
  });

  final String id;
  final String name;
  final String phone;
  final String vehicle;
  final double rating;
  bool isAvailable;
  GeoPoint location;
}
