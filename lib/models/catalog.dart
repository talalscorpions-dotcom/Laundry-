import 'enums.dart';

/// One line of a laundry partner's itemized menu — e.g. "Shirt / Wash & Fold
/// / OMR 0.600". Customers pick quantities of these when building an order.
class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.partnerId,
    required this.name,
    required this.serviceType,
    required this.price,
  });

  final String id;
  final String partnerId;
  final String name;
  final ServiceType serviceType;
  final double price;

  CatalogItem copyWith({double? price}) {
    return CatalogItem(
      id: id,
      partnerId: partnerId,
      name: name,
      serviceType: serviceType,
      price: price ?? this.price,
    );
  }
}
