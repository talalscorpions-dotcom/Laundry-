/// Flat per-leg delivery fee shown at checkout. In a real system this would
/// come from a pricing engine (distance, demand, promos); kept as a single
/// constant here so the commission math in [LaundryOrder] stays obvious.
const double kDeliveryFee = 0.500;

/// Oman uses 3 decimal places for its currency (Baisa is 1/1000 Rial).
String formatCurrency(double value) => 'OMR ${value.toStringAsFixed(3)}';

/// "1h 12m", "12m", or "45s" — used for driver pickup-time reporting on the
/// admin analytics screen, where a raw `Duration.toString()` (e.g.
/// "0:12:34.000000") would be unreadable.
String formatDuration(Duration d) {
  if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
  return '${d.inSeconds}s';
}
