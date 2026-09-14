import '../models/account.dart';
import '../models/address.dart';
import '../models/catalog.dart';
import '../models/enums.dart';
import '../models/user_models.dart';
import '../utils/password_hash.dart';

/// Seed data for the demo — one customer, two partners with itemized
/// catalogs, two drivers, one admin, and a login [Account] for each so the
/// sign-in screen has demo credentials to try. Swap this module out for
/// real API-backed repositories when connecting a backend.
class MockData {
  static const _demoPassword = 'password123';
  static const _adminPassword = 'admin123';

  static final List<Customer> customers = [
    const Customer(
      id: 'cust-1',
      name: 'Aisha Al Balushi',
      phone: '+968 9123 4567',
      addresses: [
        Address(
          id: 'addr-home',
          label: 'Home',
          line1: 'Way 2812, Al Khuwair',
          city: 'Muscat',
          location: GeoPoint(23.588, 58.407),
        ),
        Address(
          id: 'addr-work',
          label: 'Office',
          line1: 'CBD Area, Building 14',
          city: 'Muscat',
          location: GeoPoint(23.598, 58.418),
        ),
      ],
    ),
  ];

  static final List<LaundryPartner> partners = [
    // Not `const`: catalog prices are edited in place at runtime
    // (AppState.updateCatalogPrice), which a const catalog list would forbid.
    // ignore: prefer_const_constructors
    LaundryPartner(
      id: 'partner-1',
      name: 'Sparkle Laundry',
      phone: '+968 2444 5566',
      area: 'Al Khuwair',
      location: const GeoPoint(23.590, 58.410),
      rating: 4.7,
      isOpen: true,
      commissionRate: 0.20,
      verificationStatus: VerificationStatus.verified,
      catalog: [
        const CatalogItem(id: 'p1-shirt-wf', partnerId: 'partner-1', name: 'Shirt', serviceType: ServiceType.washFold, price: 0.600),
        const CatalogItem(id: 'p1-shirt-iron', partnerId: 'partner-1', name: 'Shirt', serviceType: ServiceType.ironing, price: 0.400),
        const CatalogItem(id: 'p1-suit-dc', partnerId: 'partner-1', name: 'Suit (2pc)', serviceType: ServiceType.dryClean, price: 3.500),
        const CatalogItem(id: 'p1-blanket-wf', partnerId: 'partner-1', name: 'Blanket', serviceType: ServiceType.washFold, price: 2.000),
        const CatalogItem(id: 'p1-dishdasha-iron', partnerId: 'partner-1', name: 'Dishdasha', serviceType: ServiceType.ironing, price: 0.500),
      ],
    ),
    // ignore: prefer_const_constructors
    LaundryPartner(
      id: 'partner-2',
      name: 'CleanCare Express',
      phone: '+968 2444 7788',
      area: 'Qurum',
      location: const GeoPoint(23.610, 58.470),
      rating: 4.5,
      isOpen: true,
      commissionRate: 0.18,
      verificationStatus: VerificationStatus.verified,
      catalog: [
        const CatalogItem(id: 'p2-shirt-wf', partnerId: 'partner-2', name: 'Shirt', serviceType: ServiceType.washFold, price: 0.550),
        const CatalogItem(id: 'p2-trouser-dc', partnerId: 'partner-2', name: 'Trousers', serviceType: ServiceType.dryClean, price: 1.800),
        const CatalogItem(id: 'p2-bedsheet-wf', partnerId: 'partner-2', name: 'Bedsheet (Double)', serviceType: ServiceType.washFold, price: 1.500),
        const CatalogItem(id: 'p2-curtain-dc', partnerId: 'partner-2', name: 'Curtain (per panel)', serviceType: ServiceType.dryClean, price: 4.000),
      ],
    ),
  ];

  static final List<Driver> drivers = [
    Driver(
      id: 'driver-1',
      name: 'Ali Hassan',
      phone: '+968 9555 1122',
      vehicle: 'Motorbike - OM 4521',
      rating: 4.9,
      isAvailable: true,
      location: const GeoPoint(23.592, 58.412),
      verificationStatus: VerificationStatus.verified,
    ),
    Driver(
      id: 'driver-2',
      name: 'Said Al Amri',
      phone: '+968 9555 3344',
      vehicle: 'Motorbike - OM 7788',
      rating: 4.6,
      isAvailable: true,
      location: const GeoPoint(23.605, 58.460),
      verificationStatus: VerificationStatus.verified,
    ),
  ];

  static final List<Account> accounts = [
    Account(
      id: 'acct-admin',
      name: 'Platform Admin',
      email: 'admin@laundrygo.com',
      passwordHash: hashPasswordForDemo(_adminPassword),
      role: UserRole.admin,
    ),
    Account(
      id: 'acct-cust-1',
      name: customers.first.name,
      email: 'aisha@example.com',
      passwordHash: hashPasswordForDemo(_demoPassword),
      role: UserRole.customer,
      linkedId: customers.first.id,
    ),
    Account(
      id: 'acct-partner-1',
      name: partners[0].name,
      email: 'sparkle@example.com',
      passwordHash: hashPasswordForDemo(_demoPassword),
      role: UserRole.partner,
      linkedId: partners[0].id,
    ),
    Account(
      id: 'acct-driver-1',
      name: drivers[0].name,
      email: 'ali@example.com',
      passwordHash: hashPasswordForDemo(_demoPassword),
      role: UserRole.driver,
      linkedId: drivers[0].id,
    ),
  ];
}
