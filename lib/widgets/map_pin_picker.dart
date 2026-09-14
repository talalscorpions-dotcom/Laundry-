import 'package:flutter/material.dart';

import '../models/address.dart';

/// A stylized, tap-to-place map placeholder for choosing an address's
/// location — not real map tiles. Same tradeoff as [LiveTrackingMap]: a
/// real build would swap this for `google_maps_flutter` (needs a Google
/// Maps API key with billing enabled, which this project doesn't have)
/// without changing how callers use it — they'd still just get a
/// [GeoPoint] out of [onPinChanged].
///
/// Tapping anywhere within the widget maps that position onto a small fixed
/// demo area (roughly central Muscat) to produce a [GeoPoint]; it doesn't
/// represent real geography beyond that.
class MapPinPicker extends StatelessWidget {
  const MapPinPicker({super.key, required this.pin, required this.onPinChanged});

  final GeoPoint pin;
  final ValueChanged<GeoPoint> onPinChanged;

  static const _minLat = 23.55;
  static const _maxLat = 23.65;
  static const _minLng = 58.35;
  static const _maxLng = 58.45;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final dx = (((pin.lng - _minLng) / (_maxLng - _minLng)).clamp(0.0, 1.0)) * width;
            final dy = ((1 - (pin.lat - _minLat) / (_maxLat - _minLat)).clamp(0.0, 1.0)) * height;

            return GestureDetector(
              onTapUp: (details) {
                final lng = _minLng + (details.localPosition.dx / width) * (_maxLng - _minLng);
                final lat = _minLat + (1 - details.localPosition.dy / height) * (_maxLat - _minLat);
                onPinChanged(
                  GeoPoint(lat.clamp(_minLat, _maxLat), lng.clamp(_minLng, _maxLng)),
                );
              },
              child: Container(
                color: const Color(0xFFE8F1F2),
                child: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: _GridPainter())),
                    Positioned(
                      left: dx - 16,
                      top: dy - 32,
                      child: const Icon(Icons.location_on, color: Color(0xFFE07A3F), size: 32),
                    ),
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Tap to drop a pin',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBFD8DA)
      ..strokeWidth = 1;
    const step = 24.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}
