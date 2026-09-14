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

  /// Mutable in place (a new saved address is appended by
  /// `AppState.addCustomerAddress`) while the list reference itself stays
  /// fixed — same pattern as `LaundryPartner.catalog`.
  final List<Address> addresses;

  /// A copy with its own, independent [addresses] list. See
  /// `LaundryPartner.copyForNewSession` for why this matters.
  Customer copyForNewSession() => Customer(id: id, name: name, phone: phone, addresses: List.of(addresses));
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

  /// A copy with its own, independent [catalog] list (same items, new
  /// list). `MockData.partners` is a single shared static list reused
  /// every time `AppState()` is constructed (once per app run in
  /// production, but potentially many times in tests); without this,
  /// every `AppState` would share and mutate the very same catalog.
  LaundryPartner copyForNewSession() => LaundryPartner(
        id: id,
        name: name,
        phone: phone,
        area: area,
        location: location,
        rating: rating,
        isOpen: isOpen,
        commissionRate: commissionRate,
        catalog: List.of(catalog),
        verificationStatus: verificationStatus,
        idDocumentName: idDocumentName,
        commercialRegistrationDocumentName: commercialRegistrationDocumentName,
      );
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
    Map<int, Set<int>>? weeklyAvailability,
  }) : weeklyAvailability = weeklyAvailability ?? defaultWeeklyAvailability();

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

  /// Weekday (`DateTime.monday`..`DateTime.sunday`) -> the set of slot
  /// indices (into `utils/scheduling.dart`'s `kSlotWindows`, 0..5 for the
  /// six 9am-9pm windows) the driver is rostered for that day, every week.
  /// Edited on the driver's "My schedule" screen; read by AppState's
  /// booking-capacity checks (`isSlotFullyBooked`, `driversAvailableForSlot`)
  /// so a customer/partner can see when a slot has no rostered driver left.
  final Map<int, Set<int>> weeklyAvailability;

  bool isAvailableAt(int weekday, int slotIndex) => weeklyAvailability[weekday]?.contains(slotIndex) ?? false;

  /// Every day, every slot — the default for a brand new driver, so a
  /// freshly created (or pre-seeded demo) account doesn't make every
  /// booking slot look "fully booked" before they've ever visited the
  /// schedule screen. (6 slots, matching `kSlotWindows.length`.)
  static Map<int, Set<int>> defaultWeeklyAvailability() => {
        for (var day = DateTime.monday; day <= DateTime.sunday; day++) day: {0, 1, 2, 3, 4, 5},
      };

  /// A copy with its own, independent [weeklyAvailability] map (and mutable
  /// [isAvailable]/[location] state). See
  /// [LaundryPartner.copyForNewSession] for why this matters — the same
  /// aliasing risk applies here.
  Driver copyForNewSession() => Driver(
        id: id,
        name: name,
        phone: phone,
        vehicle: vehicle,
        rating: rating,
        isAvailable: isAvailable,
        location: location,
        verificationStatus: verificationStatus,
        residentialIdDocumentName: residentialIdDocumentName,
        driverLicenseDocumentName: driverLicenseDocumentName,
        weeklyAvailability: {for (final entry in weeklyAvailability.entries) entry.key: Set.of(entry.value)},
      );
}
