import '../../core/routeros/routeros_service.dart';
import 'voucher_lifecycle_action_result.dart';

class HotspotTicketLifecycleService {
  final RouterOsService service;
  const HotspotTicketLifecycleService(this.service);

  Future<VoucherLifecycleActionResult> deleteTicket(
    Map<String, String> ticket,
  ) async {
    final username = ticket['name'] ?? '';
    try {
      if (username.isEmpty || ticket['.id'] == null) {
        return VoucherLifecycleActionResult(
          username: username,
          error: 'Ticket invalide : username ou identifiant RouterOS absent.',
        );
      }

      final beforeCookies = await service.hotspotCookies();
      final beforeActive = await service.activeUsers();
      final beforeSchedulers = await service.schedulers();

      await service.removeHotspotUserAndScheduler(ticket);

      return VoucherLifecycleActionResult(
        username: username,
        cookiesRemoved: beforeCookies
            .where((e) => e['user'] == username)
            .length,
        sessionsRemoved: beforeActive
            .where((e) => e['user'] == username)
            .length,
        schedulersRemoved: beforeSchedulers
            .where((e) => e['name'] == username)
            .length,
        userRemoved: true,
      );
    } catch (e) {
      return VoucherLifecycleActionResult(username: username, error: '$e');
    }
  }

  Future<VoucherLifecycleActionResult> resetTicket(
    Map<String, String> ticket,
  ) async {
    final username = ticket['name'] ?? '';
    try {
      if (username.isEmpty || ticket['.id'] == null) {
        return VoucherLifecycleActionResult(
          username: username,
          error: 'Ticket invalide : username ou identifiant RouterOS absent.',
        );
      }

      final beforeCookies = await service.hotspotCookies();
      final beforeActive = await service.activeUsers();
      final beforeSchedulers = await service.schedulers();

      await service.resetRootMikroManagerHotspotUser(ticket);

      return VoucherLifecycleActionResult(
        username: username,
        cookiesRemoved: beforeCookies
            .where((e) => e['user'] == username)
            .length,
        sessionsRemoved: beforeActive
            .where((e) => e['user'] == username)
            .length,
        schedulersRemoved: beforeSchedulers
            .where((e) => e['name'] == username)
            .length,
        countersReset: true,
      );
    } catch (e) {
      return VoucherLifecycleActionResult(username: username, error: '$e');
    }
  }

  Future<VoucherLifecycleActionResult> clearSession(String username) async {
    try {
      final result = await service.cleanupHotspotUserSession(username);
      return VoucherLifecycleActionResult(
        username: username,
        cookiesRemoved: result['cookiesRemoved'] ?? 0,
        sessionsRemoved: result['activeRemoved'] ?? 0,
      );
    } catch (e) {
      return VoucherLifecycleActionResult(username: username, error: '$e');
    }
  }
}
