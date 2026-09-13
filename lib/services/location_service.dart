import 'dart:async';

import '../models/address.dart';

/// Abstraction over a live-location provider so a real GPS/maps SDK
/// (Google Maps + a fused location provider, Mapbox, a driver app's own
/// location beacon over a websocket...) can replace the simulated stream
/// below without any tracking-UI changes.
abstract class LocationTracker {
  Stream<GeoPoint> watch(String subjectId, {required GeoPoint from, required GeoPoint to});
}

/// Simulates a driver travelling in a straight line from [from] to [to]
/// over ~20 seconds, emitting a position twice a second. Good enough to
/// demo the tracking UI end to end; a real implementation would stream
/// actual device coordinates along a routed path.
class SimulatedLocationTracker implements LocationTracker {
  @override
  Stream<GeoPoint> watch(String subjectId, {required GeoPoint from, required GeoPoint to}) {
    late final StreamController<GeoPoint> controller;
    Timer? timer;
    var step = 0;
    const totalSteps = 40;

    controller = StreamController<GeoPoint>(
      onListen: () {
        timer = Timer.periodic(const Duration(milliseconds: 500), (t) {
          step++;
          final progress = (step / totalSteps).clamp(0.0, 1.0);
          controller.add(from.lerp(to, progress));
          if (progress >= 1.0) {
            t.cancel();
            controller.close();
          }
        });
      },
      onCancel: () => timer?.cancel(),
    );
    return controller.stream;
  }
}
