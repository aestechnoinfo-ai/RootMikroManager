import 'dart:async';

import 'sales_cache_repository.dart';

class SalesSyncCoordinator {
  SalesSyncCoordinator._();
  static final instance = SalesSyncCoordinator._();
  static const ttl = Duration(minutes: 5);

  final repository = const SalesCacheRepository();
  Future<void>? _inFlight;
  Timer? _timer;

  Future<void> sync({
    required int routerId,
    required Future<List<Map<String, String>>> Function() fetch,
    bool force = false,
  }) async {
    if (_inFlight != null) return _inFlight;
    if (!force) {
      final cache = await repository.read(routerId);
      if (cache.isFresh(DateTime.now().toUtc(), ttl)) return;
    }
    final operation = () async {
      final rows = await fetch();
      await repository.replace(routerId, rows);
    }();
    _inFlight = operation;
    try {
      await operation;
    } finally {
      if (identical(_inFlight, operation)) _inFlight = null;
    }
  }

  void startPeriodic({
    required int routerId,
    required Future<List<Map<String, String>>> Function() fetch,
  }) {
    stopPeriodic();
    _timer = Timer.periodic(ttl, (_) {
      unawaited(sync(routerId: routerId, fetch: fetch));
    });
  }

  void stopPeriodic() {
    _timer?.cancel();
    _timer = null;
  }
}
