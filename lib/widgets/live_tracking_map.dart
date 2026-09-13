import 'dart:math';

import 'package:flutter/material.dart';

import '../models/address.dart';
import '../services/location_service.dart';

/// Visual placeholder for "live GPS tracking": draws a simple route between
/// two points and animates a marker along it, driven by a real [LocationTracker]
/// stream. Swap [tracker] for one backed by an actual maps SDK and this
/// widget's plumbing (the StreamBuilder, the progress math) barely changes —
/// only the painter would be replaced by a real map widget.
class LiveTrackingMap extends StatefulWidget {
  const LiveTrackingMap({
    super.key,
    required this.tracker,
    required this.from,
    required this.to,
    required this.subjectLabel,
  });

  final LocationTracker tracker;
  final GeoPoint from;
  final GeoPoint to;
  final String subjectLabel;

  @override
  State<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<LiveTrackingMap> {
  late final Stream<GeoPoint> _stream = widget.tracker.watch('track', from: widget.from, to: widget.to);
  late GeoPoint _current = widget.from;

  double _distance(GeoPoint a, GeoPoint b) => sqrt(pow(a.lat - b.lat, 2) + pow(a.lng - b.lng, 2));

  double get _progress {
    final total = _distance(widget.from, widget.to);
    if (total == 0) return 1;
    return (_distance(widget.from, _current) / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GeoPoint>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) _current = snapshot.data!;
        final arrived = snapshot.connectionState == ConnectionState.done;
        return AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFD8DA)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _RoutePainter(progress: _progress)),
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
                    child: Text(
                      arrived ? '${widget.subjectLabel} has arrived' : 'Tracking ${widget.subjectLabel} • live',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(size.width * 0.12, size.height * 0.85);
    final end = Offset(size.width * 0.88, size.height * 0.15);

    final routePaint = Paint()
      ..color = const Color(0xFFBFD8DA)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, routePaint);

    final travelledPaint = Paint()
      ..color = const Color(0xFF1F8A70)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final current = Offset.lerp(start, end, progress)!;
    canvas.drawLine(start, current, travelledPaint);

    canvas.drawCircle(start, 6, Paint()..color = const Color(0xFF1F8A70));
    canvas.drawCircle(end, 6, Paint()..color = const Color(0xFFE07A3F));
    canvas.drawCircle(current, 8, Paint()..color = Colors.white);
    canvas.drawCircle(
      current,
      8,
      Paint()
        ..color = const Color(0xFF1F8A70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) => oldDelegate.progress != progress;
}
