import 'address.dart';
import 'catalog.dart';
import 'enums.dart';

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
///
/// [idDocumentName] and [commercialRegistrationDocumentName] are the file
/// names of the two documents a business must submit at sign-up (an owner
/// ID and a Commercial Registration) — see the big caveat on
/// [DocumentPickerField] about what this demo does and doesn't do with
/// them. They're null for the pre-seeded demo partners, which are already
/// [VerificationStatus.verified].
class LaundryPartner {
  const LaundryPartner({
    required this.id,
    required this.name,
    required this.phone,
    required this.area,
    required this.location,
    required this.rating,
    required this.isOpen,
    required this.commissionRate,
    required this.catalog,
    this.verificationStatus = VerificationStatus.pending,
    this.idDocumentName,
    this.commercialRegistrationDocumentName,
  });

  final String id;
  final String name;
  final String phone;
  final String area;
  final GeoPoint location;
  final double rating;
  final bool isOpen;

  /// e.g. 0.20 == the platform takes 20% of every order's item subtotal.
  final double commissionRate;

  /// Mutable in place (prices are edited by the partner) while the list
  /// reference itself stays fixed.
  final List<CatalogItem> catalog;

  final VerificationStatus verificationStatus;
  final String? idDocumentName;
  final String? commercialRegistrationDocumentName;
}

/// [residentialIdDocumentName] and [driverLicenseDocumentName] are the two
/// documents a driver must submit at sign-up. Null for the pre-seeded demo
/// drivers, which are already [VerificationStatus.verified].
class Driver {
  Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicle,
    required this.rating,
    required this.isAvailable,
    required this.location,
    this.verificationStatus = VerificationStatus.pending,
    this.residentialIdDocumentName,
    this.driverLicenseDocumentName,
  });

  final String id;
  final String name;
  final String phone;
  final String vehicle;
  final double rating;
  bool isAvailable;
  GeoPoint location;

  final VerificationStatus verificationStatus;
  final String? residentialIdDocumentName;
  final String? driverLicenseDocumentName;
}
