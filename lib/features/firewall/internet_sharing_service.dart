import '../../core/routeros/routeros_service.dart';
import 'internet_sharing_rule.dart';

class InternetSharingService {
  final RouterOsService service;
  const InternetSharingService(this.service);

  Future<List<String>> interfaces() async {
    final rows = await service.client.print('/interface');
    final names =
        rows
            .map((r) => (r['name'] ?? '').trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return names;
  }

  Future<List<InternetSharingRule>> managedRules() async {
    final rows = await service.client.print('/ip/firewall/mangle');
    return rows
        .where(InternetSharingRule.isManaged)
        .map(InternetSharingRule.fromRouterOs)
        .toList()
      ..sort((a, b) => a.interfaceName.compareTo(b.interfaceName));
  }

  Future<InternetSharingRule?> findForInterface(String interfaceName) async {
    final rules = await managedRules();
    for (final rule in rules) {
      if (rule.interfaceName == interfaceName) return rule;
    }
    return null;
  }

  Future<void> disableInternetSharing({
    required String interfaceName,
    int ttl = 1,
  }) async {
    if (interfaceName.trim().isEmpty) {
      throw ArgumentError('Interface obligatoire.');
    }
    if (ttl < 1 || ttl > 255) {
      throw ArgumentError('TTL doit être compris entre 1 et 255.');
    }

    final existing = await findForInterface(interfaceName);
    final values = <String, String>{
      'chain': 'postrouting',
      'out-interface': interfaceName,
      'action': 'change-ttl',
      'new-ttl': 'set:$ttl',
      'passthrough': 'yes',
      'disabled': 'no',
      'comment':
          '${InternetSharingRule.marker} | interface=$interfaceName | ttl=$ttl',
    };

    if (existing == null || existing.id.isEmpty) {
      await service.add('/ip/firewall/mangle', values);
    } else {
      await service.set('/ip/firewall/mangle', existing.id, values);
    }
  }

  Future<void> setEnabled(InternetSharingRule rule, bool enabled) async {
    if (rule.id.isEmpty) return;
    if (enabled) {
      await service.enable('/ip/firewall/mangle', rule.id);
    } else {
      await service.disable('/ip/firewall/mangle', rule.id);
    }
  }

  Future<void> updateTtl(InternetSharingRule rule, int ttl) async {
    if (rule.id.isEmpty) return;
    if (ttl < 1 || ttl > 255) {
      throw ArgumentError('TTL doit être compris entre 1 et 255.');
    }
    await service.set('/ip/firewall/mangle', rule.id, {
      'new-ttl': 'set:$ttl',
      'comment':
          '${InternetSharingRule.marker} | interface=${rule.interfaceName} | ttl=$ttl',
    });
  }

  Future<void> remove(InternetSharingRule rule) async {
    if (rule.id.isEmpty) return;
    await service.remove('/ip/firewall/mangle', rule.id);
  }
}
