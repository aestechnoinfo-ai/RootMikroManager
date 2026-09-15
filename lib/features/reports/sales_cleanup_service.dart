import '../../core/routeros/routeros_service.dart';
import 'rootmikromanager_sales_record.dart';
import 'sales_date_utils.dart';

class SalesCleanupCandidate {
  final Map<String, String> raw;
  final RootMikroManagerSalesRecord record;
  const SalesCleanupCandidate(this.raw, this.record);
}

class SalesCleanupResult {
  final int selected;
  final int removed;
  final List<String> failures;

  const SalesCleanupResult({
    required this.selected,
    required this.removed,
    required this.failures,
  });
}

class SalesCleanupService {
  final RouterOsService service;
  const SalesCleanupService(this.service);

  Future<List<SalesCleanupCandidate>> candidatesForDay(DateTime date) async {
    final rows = await service.rootmikromanagerSalesScripts();
    return _filter(rows, (r) => SalesDateUtils.sameDay(r.date, date));
  }

  Future<List<SalesCleanupCandidate>> candidatesForMonth(DateTime date) async {
    final rows = await service.rootmikromanagerSalesScripts();
    return _filter(rows, (r) => SalesDateUtils.sameMonth(r.date, date));
  }

  List<SalesCleanupCandidate> _filter(
    List<Map<String, String>> rows,
    bool Function(RootMikroManagerSalesRecord record) predicate,
  ) {
    final out = <SalesCleanupCandidate>[];
    for (final raw in rows) {
      final record = RootMikroManagerSalesRecord.fromRouterOs(raw);
      if (record.isValid && predicate(record)) {
        out.add(SalesCleanupCandidate(raw, record));
      }
    }
    return out;
  }

  Future<SalesCleanupResult> remove(
    List<SalesCleanupCandidate> candidates,
  ) async {
    var removed = 0;
    final failures = <String>[];

    for (final candidate in candidates) {
      final id = candidate.raw['.id'];
      if (id == null) {
        failures.add('${candidate.record.username} : identifiant absent.');
        continue;
      }
      try {
        await service.remove('/system/script', id);
        removed++;
      } catch (e) {
        failures.add('${candidate.record.username} : $e');
      }
    }

    return SalesCleanupResult(
      selected: candidates.length,
      removed: removed,
      failures: failures,
    );
  }
}
