import '../../core/routeros/routeros_service.dart';
import 'hotspot_ticket_lifecycle_service.dart';
import 'voucher_batch_action_result.dart';

class VoucherBatchLifecycleService {
  final RouterOsService service;
  const VoucherBatchLifecycleService(this.service);

  Future<VoucherBatchActionResult> deleteTickets(
    List<Map<String, String>> tickets, {
    void Function(int completed)? onProgress,
  }) async {
    final lifecycle = HotspotTicketLifecycleService(service);
    final results = <VoucherBatchItemResult>[];

    for (final ticket in tickets) {
      final username = ticket['name'] ?? '—';
      final result = await lifecycle.deleteTicket(ticket);
      results.add(
        VoucherBatchItemResult(
          username: username,
          success: result.success,
          message: result.success
              ? 'Supprimé : ${result.cookiesRemoved} cookie(s), '
                    '${result.sessionsRemoved} session(s), '
                    '${result.schedulersRemoved} scheduler(s).'
              : result.error ?? 'Échec inconnu.',
        ),
      );
      onProgress?.call(results.length);
    }

    return VoucherBatchActionResult(results);
  }

  Future<VoucherBatchActionResult> resetTickets(
    List<Map<String, String>> tickets,
  ) async {
    final lifecycle = HotspotTicketLifecycleService(service);
    final results = <VoucherBatchItemResult>[];

    for (final ticket in tickets) {
      final username = ticket['name'] ?? '—';
      final result = await lifecycle.resetTicket(ticket);
      results.add(
        VoucherBatchItemResult(
          username: username,
          success: result.success,
          message: result.success
              ? 'Réinitialisé : ${result.cookiesRemoved} cookie(s), '
                    '${result.sessionsRemoved} session(s), '
                    '${result.schedulersRemoved} scheduler(s).'
              : result.error ?? 'Échec inconnu.',
        ),
      );
    }

    return VoucherBatchActionResult(results);
  }
}
