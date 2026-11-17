/// Someone at the store right now.
class Trip {
  const Trip({required this.shopperId, required this.shopperName, required this.since});

  final String shopperId;
  final String shopperName;
  final DateTime since;

  /// A trip older than this counts as finished, even if nobody tapped Done.
  static const maxLength = Duration(hours: 3);

  bool isActive(DateTime now) => now.difference(since) < maxLength;
}

/// The result of tapping "I'm at the store".
sealed class TripStart {
  const TripStart();
}

class TripStarted extends TripStart {
  const TripStarted(this.notified);
  final int notified;
}

class TripTaken extends TripStart {
  const TripTaken(this.shopperName);
  final String shopperName;
}
