/// Flat per-leg delivery fee shown at checkout. In a real system this would
/// come from a pricing engine (distance, demand, promos); kept as a single
/// constant here so the commission math in [LaundryOrder] stays obvious.
const double kDeliveryFee = 0.500;

/// Oman uses 3 decimal places for its currency (Baisa is 1/1000 Rial).
String formatCurrency(double value) => 'OMR ${value.toStringAsFixed(3)}';
