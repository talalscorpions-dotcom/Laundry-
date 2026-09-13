/// Abstraction over push/SMS notifications so a real provider (FCM, SNS,
/// Twilio...) can replace the in-memory feed without touching business
/// logic — every call site already reads through this interface.
abstract class NotificationService {
  void notify(String audienceId, String message);
  List<String> feedFor(String audienceId);
}

class InMemoryNotificationService implements NotificationService {
  final Map<String, List<String>> _feeds = {};

  @override
  void notify(String audienceId, String message) {
    _feeds.putIfAbsent(audienceId, () => []).insert(0, message);
  }

  @override
  List<String> feedFor(String audienceId) => List.unmodifiable(_feeds[audienceId] ?? const []);
}
