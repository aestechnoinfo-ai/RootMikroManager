import '../../data/models/router_model.dart';
import '../../features/hotspot/hotspot_profile_config.dart';
import '../constants/rootmikromanager_markers.dart';
import 'routeros_client.dart';

class RouterOsService {
  final RouterOsClient client = RouterOsClient();

  bool get isConnected => client.isConnected;

  Future<void> connect(
    RouterModel router,
    String password, {
    bool allowSelfSignedCertificate = true,
  }) async {
    final useTls = router.useTls || router.port == 8729;

    try {
      await client.connect(
        router.host,
        port: router.port,
        secure: useTls,
        allowBadCertificate: useTls && allowSelfSignedCertificate,
      );
      await client.login(router.username, password);
    } catch (_) {
      // A socket can be open even when RouterOS rejects authentication.
      // Never expose that transport state as an authenticated session.
      await client.close();
      rethrow;
    }
  }

  Future<Map<String, String>> identity() => client.first('/system/identity');
  Future<Map<String, String>> resource() => client.first('/system/resource');
  Future<Map<String, String>> systemClock() => client.first('/system/clock');
  Future<Map<String, String>> routerboard() async {
    try {
      return await client.first('/system/routerboard');
    } catch (_) {
      return <String, String>{};
    }
  }

  // HOTSPOT
  Future<List<Map<String, String>>> hotspotUsers() =>
      _hotspotRead('/ip/hotspot/user');

  Future<List<Map<String, String>>> _hotspotRead(
    String path, {
    Map<String, String> where = const {},
    List<String> arguments = const [],
  }) => client.print(
    path,
    where: where,
    arguments: arguments,
    idleTimeout: const Duration(seconds: 15),
    withoutTotalTimeout: true,
  );

  /// Comptage serveur destiné au tableau de bord.
  ///
  /// Une seule requête globale est utilisée, exactement comme le tableau de
  /// bord Mikhmon. Son coût réseau reste constant avec 50 000 comptes : aucune
  /// ligne utilisateur n'est transférée et le routeur ne répète pas un
  /// balayage complet pour chacun de ses profils.
  Future<List<Map<String, String>>> hotspotUsersDashboardSummary() async {
    final count = await client.count(
      '/ip/hotspot/user',
      idleTimeout: const Duration(seconds: 15),
      withoutTotalTimeout: true,
    );
    return [
      {'profile': 'Tous les profils', 'dashboard-count': count.toString()},
    ];
  }

  Future<List<Map<String, String>>> hotspotProfiles() =>
      _hotspotRead('/ip/hotspot/user/profile');
  Future<List<Map<String, String>>> hotspotServers() =>
      _hotspotRead('/ip/hotspot');
  Future<List<Map<String, String>>> hotspotServerProfiles() =>
      _hotspotRead('/ip/hotspot/profile');
  Future<List<Map<String, String>>> activeUsers({String? server}) {
    final where = <String, String>{};
    if (server != null && server.isNotEmpty && server != 'all') {
      where['server'] = server;
    }
    return _hotspotRead('/ip/hotspot/active', where: where);
  }

  Future<List<Map<String, String>>> hotspotCookies() =>
      _hotspotRead('/ip/hotspot/cookie');

  Future<List<Map<String, String>>> hotspotHosts({
    bool authorizedOnly = false,
    bool bypassedOnly = false,
  }) {
    final where = <String, String>{};
    if (authorizedOnly) where['authorized'] = 'true';
    if (bypassedOnly) where['bypassed'] = 'true';

    return _hotspotRead('/ip/hotspot/host', where: where);
  }

  Future<List<Map<String, String>>> hotspotIpBindings() =>
      _hotspotRead('/ip/hotspot/ip-binding');

  Future<List<Map<String, String>>> hotspotUsersByName(String name) =>
      _hotspotRead('/ip/hotspot/user', where: {'name': name});

  Future<List<Map<String, String>>> hotspotUsersFiltered({
    String? profile,
    String? comment,
    bool expiredOnly = false,
  }) {
    final where = <String, String>{};
    if (profile != null && profile.isNotEmpty && profile != 'all') {
      where['profile'] = profile;
    }
    if (comment != null && comment.isNotEmpty) {
      where['comment'] = comment;
    }
    if (expiredOnly) {
      where['limit-uptime'] = '1s';
    }
    return _hotspotRead('/ip/hotspot/user', where: where);
  }

  Future<Map<String, String>> hotspotUserById(String id) async {
    final rows = await _hotspotRead('/ip/hotspot/user', where: {'.id': id});
    return rows.isEmpty ? <String, String>{} : rows.first;
  }

  Future<void> updateHotspotUser({
    required String id,
    required String server,
    required String name,
    required String password,
    required String profile,
    required bool enabled,
    required String timeLimit,
    required int dataLimitBytes,
    required String comment,
  }) => set('/ip/hotspot/user', id, {
    'server': server,
    'name': name,
    'password': password,
    'profile': profile,
    'disabled': enabled ? 'no' : 'yes',
    'limit-uptime': timeLimit.trim().isEmpty ? '0' : timeLimit.trim(),
    'limit-bytes-total': dataLimitBytes.toString(),
    'comment': comment.trim(),
  });

  Future<void> resetRootMikroManagerHotspotUser(
    Map<String, String> user,
  ) async {
    final id = user['.id'];
    final name = user['name'] ?? '';
    if (id == null) return;

    if (name.isNotEmpty) {
      await cleanupHotspotUserSession(name);
    }

    await set('/ip/hotspot/user', id, {'limit-uptime': '0', 'comment': ''});

    final reset = await client.command([
      '/ip/hotspot/user/reset-counters',
      '=.id=$id',
    ]);
    _throwIfError(reset);

    if (name.isNotEmpty) {
      final schedulers = await client.print(
        '/system/scheduler',
        where: {'name': name},
      );
      for (final row in schedulers) {
        final schedulerId = row['.id'];
        if (schedulerId != null) {
          await remove('/system/scheduler', schedulerId);
        }
      }
    }
  }

  Future<Map<String, int>> cleanupHotspotUserSession(String username) async {
    var cookiesRemoved = 0;
    var activeRemoved = 0;
    final cookies = await client.print(
      '/ip/hotspot/cookie',
      where: {'user': username},
    );
    for (final row in cookies) {
      final id = row['.id'];
      if (id == null) continue;
      await remove('/ip/hotspot/cookie', id);
      cookiesRemoved++;
    }
    final active = await client.print(
      '/ip/hotspot/active',
      where: {'user': username},
    );
    for (final row in active) {
      final id = row['.id'];
      if (id == null) continue;
      await remove('/ip/hotspot/active', id);
      activeRemoved++;
    }
    return {'cookiesRemoved': cookiesRemoved, 'activeRemoved': activeRemoved};
  }

  Future<Map<String, int>> cleanupExpiredHotspotUsers() async {
    final rows = await hotspotUsersFiltered(expiredOnly: true);
    var cookiesRemoved = 0;
    var activeRemoved = 0;
    var schedulersRemoved = 0;
    var usersRemoved = 0;
    for (final row in rows) {
      final id = row['.id'];
      final username = row['name'] ?? '';
      if (id == null) continue;
      if (username.isNotEmpty) {
        final c = await cleanupHotspotUserSession(username);
        cookiesRemoved += c['cookiesRemoved'] ?? 0;
        activeRemoved += c['activeRemoved'] ?? 0;
        final schedulers = await client.print(
          '/system/scheduler',
          where: {'name': username},
        );
        for (final scheduler in schedulers) {
          final schedulerId = scheduler['.id'];
          if (schedulerId != null) {
            await remove('/system/scheduler', schedulerId);
            schedulersRemoved++;
          }
        }
      }
      await remove('/ip/hotspot/user', id);
      usersRemoved++;
    }
    return {
      'usersMatched': rows.length,
      'cookiesRemoved': cookiesRemoved,
      'activeRemoved': activeRemoved,
      'schedulersRemoved': schedulersRemoved,
      'usersRemoved': usersRemoved,
    };
  }

  Future<int> removeExpiredHotspotUsers() async {
    final result = await cleanupExpiredHotspotUsers();
    return result['usersRemoved'] ?? 0;
  }

  Future<List<Map<String, String>>> hotspotUsersByExactComment(
    String comment,
  ) => _hotspotRead('/ip/hotspot/user', where: {'comment': comment});

  Future<int> removeUnusedHotspotUsersByComment(String comment) async {
    // RouterOS may serialize a zero duration as `0s` or `00:00:00`.
    // Mikhmon uses both representations in its print/removal screens.
    final matches = await hotspotUsersByExactComment(comment);
    final rows = matches.where((row) {
      final uptime = (row['uptime'] ?? '').trim().toLowerCase();
      return uptime.isEmpty || uptime == '0s' || uptime == '00:00:00';
    });

    var count = 0;
    for (final row in rows) {
      final id = row['.id'];
      final name = row['name'] ?? '';
      if (id == null) continue;
      if (name.isNotEmpty) {
        await cleanupHotspotUserSession(name);
        final schedulers = await client.print(
          '/system/scheduler',
          where: {'name': name},
        );
        for (final scheduler in schedulers) {
          final schedulerId = scheduler['.id'];
          if (schedulerId != null) {
            await remove('/system/scheduler', schedulerId);
          }
        }
      }
      await remove('/ip/hotspot/user', id);
      count++;
    }
    return count;
  }

  Future<void> removeHotspotUserAndScheduler(Map<String, String> user) async {
    final id = user['.id'];
    final name = user['name'] ?? '';
    if (id == null) return;

    if (name.isNotEmpty) {
      await cleanupHotspotUserSession(name);
      final schedulers = await client.print(
        '/system/scheduler',
        where: {'name': name},
      );
      for (final row in schedulers) {
        final schedulerId = row['.id'];
        if (schedulerId != null) {
          await remove('/system/scheduler', schedulerId);
        }
      }
    }

    await remove('/ip/hotspot/user', id);
  }

  Future<List<Map<String, String>>> ipPools() => client.print('/ip/pool');

  Future<List<Map<String, String>>> staticSimpleQueues() =>
      client.collect('/queue/simple/print', arguments: ['?dynamic=false']);

  Future<void> saveRootMikroManagerHotspotProfile(
    HotspotProfileConfig config,
  ) async {
    final values = <String, String>{
      'name': config.name,
      'address-pool': config.addressPool,
      'rate-limit': config.rateLimit,
      'shared-users': config.sharedUsers.toString(),
      'status-autorefresh': '1m',
      'on-login': RootMikroManagerProfileScriptCodec.buildOnLogin(config),
      'parent-queue': config.parentQueue,
    };

    if (config.id == null) {
      await add('/ip/hotspot/user/profile', values);
    } else {
      await set('/ip/hotspot/user/profile', config.id!, values);
    }

    await _syncRootMikroManagerProfileScheduler(config);
  }

  Future<void> deleteRootMikroManagerHotspotProfile(
    Map<String, String> profile,
  ) async {
    final id = profile['.id'];
    final name = profile['name'] ?? '';
    if (id == null) return;

    await remove('/ip/hotspot/user/profile', id);
    await _removeSchedulersNamed(name);
  }

  Future<void> _syncRootMikroManagerProfileScheduler(
    HotspotProfileConfig config,
  ) async {
    final schedulers = await this.schedulers();

    bool legacyProfileMonitor(Map<String, String> row) =>
        (row['comment'] ?? '').startsWith('Monitor Profile ');
    final matchingCurrent = schedulers
        .where((row) => row['name'] == config.name && legacyProfileMonitor(row))
        .toList();
    final matchingOriginal =
        config.originalName.isEmpty || config.originalName == config.name
        ? <Map<String, String>>[]
        : schedulers
              .where(
                (row) =>
                    row['name'] == config.originalName &&
                    legacyProfileMonitor(row),
              )
              .toList();

    // Per-user schedulers created by on-login now own the expiration. Remove
    // legacy profile scanners so date arithmetic is never duplicated.
    for (final row in [...matchingCurrent, ...matchingOriginal]) {
      final id = row['.id'];
      if (id != null) {
        await remove('/system/scheduler', id);
      }
    }
  }

  Future<void> _removeSchedulersNamed(String name) async {
    if (name.isEmpty) return;
    final rows = await schedulers();
    for (final row in rows.where((row) => row['name'] == name)) {
      final id = row['.id'];
      if (id != null) {
        await remove('/system/scheduler', id);
      }
    }
  }

  Future<void> resetFirewallRuleCounters(String path, String id) async {
    final reply = await client.command(['$path/reset-counters', '=.id=$id']);
    _throwIfError(reply);
  }

  Future<void> moveFirewallRule(
    String path,
    String id, {
    required String destinationId,
  }) async {
    final reply = await client.command([
      '$path/move',
      '=.id=$id',
      '=destination=$destinationId',
    ]);
    _throwIfError(reply);
  }

  Future<void> duplicateFirewallRule(
    String path,
    Map<String, String> row,
  ) async {
    const ignored = <String>{
      '.id',
      'bytes',
      'packets',
      'dynamic',
      'dummy',
      'invalid',
      'hw-offloaded',
    };
    final values = <String, String>{};
    for (final entry in row.entries) {
      if (ignored.contains(entry.key)) continue;
      if (entry.key.startsWith('.')) continue;
      if (entry.value.isEmpty) continue;
      values[entry.key] = entry.value;
    }
    values['disabled'] = 'yes';
    final comment = values['comment'] ?? '';
    values['comment'] = comment.isEmpty ? 'Copie' : '$comment • Copie';
    await add(path, values);
  }

  // PPP
  Future<List<Map<String, String>>> pppSecrets() => client.print('/ppp/secret');
  Future<List<Map<String, String>>> pppProfiles() =>
      client.print('/ppp/profile');
  Future<List<Map<String, String>>> pppActive() => client.print('/ppp/active');

  Future<List<Map<String, String>>> pppInterfaces() async {
    final paths = [
      '/interface/pppoe-server',
      '/interface/l2tp-server',
      '/interface/sstp-server',
      '/interface/ovpn-server',
      '/interface/pptp-server',
    ];
    final result = <Map<String, String>>[];
    for (final path in paths) {
      try {
        final rows = await client.print(path);
        for (final row in rows) {
          result.add({...row, '_source-path': path});
        }
      } catch (_) {}
    }
    return result;
  }

  Future<List<Map<String, String>>> pppoeServerSettings() =>
      client.print('/interface/pppoe-server/server');

  Future<void> disconnectPppActive(String id) => remove('/ppp/active', id);

  Future<void> resetPppSecretCounters(String id) async {
    final reply = await client.command([
      '/ppp/secret/reset-counters',
      '=.id=$id',
    ]);
    _throwIfError(reply);
  }

  Future<void> setSystemIdentity(String name) async {
    final reply = await client.command(['/system/identity/set', '=name=$name']);
    _throwIfError(reply);
  }

  Future<void> setSystemClock({
    required String date,
    required String time,
    required String timeZoneName,
    required bool timeZoneAutodetect,
  }) async {
    final words = <String>[
      '/system/clock/set',
      if (date.isNotEmpty) '=date=$date',
      if (time.isNotEmpty) '=time=$time',
      '=time-zone-autodetect=${timeZoneAutodetect ? 'yes' : 'no'}',
      if (!timeZoneAutodetect && timeZoneName.isNotEmpty)
        '=time-zone-name=$timeZoneName',
    ];
    final reply = await client.command(words);
    _throwIfError(reply);
  }

  Future<List<Map<String, String>>> systemUsers() => client.print('/user');

  Future<List<Map<String, String>>> systemUserGroups() =>
      client.print('/user/group');

  Future<List<Map<String, String>>> ipServices() => client.print('/ip/service');

  Future<List<Map<String, String>>> certificates() =>
      client.print('/certificate');

  // NETWORK
  Future<List<Map<String, String>>> dhcpLeases() =>
      client.print('/ip/dhcp-server/lease');
  Future<List<Map<String, String>>> dhcpServers() =>
      client.print('/ip/dhcp-server');

  Future<List<Map<String, String>>> dhcpNetworks() =>
      client.print('/ip/dhcp-server/network');

  Future<void> makeDhcpLeaseStatic(String id) async {
    final reply = await client.command([
      '/ip/dhcp-server/lease/make-static',
      '=.id=$id',
    ]);
    _throwIfError(reply);
  }

  Future<List<Map<String, String>>> dnsStatic() =>
      client.print('/ip/dns/static');
  Future<Map<String, String>> dnsSettings() => client.first('/ip/dns');

  Future<void> setDnsSettings(Map<String, String> values) async {
    final reply = await client.command([
      '/ip/dns/set',
      ...values.entries.map((e) => '=${e.key}=${e.value}'),
    ]);
    _throwIfError(reply);
  }

  Future<List<Map<String, String>>> dnsCacheAll() async {
    try {
      return await client.print('/ip/dns/cache/all');
    } catch (_) {
      return client.print('/ip/dns/cache');
    }
  }

  Future<void> flushDnsCache() async {
    final reply = await client.command(['/ip/dns/cache/flush']);
    _throwIfError(reply);
  }

  Future<List<Map<String, String>>> dnsAdlists() =>
      client.print('/ip/dns/adlist');

  Future<List<Map<String, String>>> resolveDns(String name) =>
      client.collect('/resolve', arguments: ['=domain-name=$name']);

  Future<List<Map<String, String>>> interfaces() => client.print('/interface');
  Future<Map<String, String>> interfaceEthernetMonitorOnce(
    String interfaceName,
  ) async {
    try {
      final rows = await client.collect(
        '/interface/ethernet/monitor',
        arguments: ['=numbers=$interfaceName', '=once='],
      );
      return rows.isEmpty ? <String, String>{} : rows.first;
    } catch (_) {
      return <String, String>{};
    }
  }

  Future<Map<String, String>> ipAddressById(String id) async {
    final rows = await client.print('/ip/address', where: {'.id': id});
    return rows.isEmpty ? <String, String>{} : rows.first;
  }

  Future<List<Map<String, String>>> vlanInterfaces() =>
      client.print('/interface/vlan');

  Future<List<Map<String, String>>> bridges() =>
      client.print('/interface/bridge');

  Future<List<Map<String, String>>> bridgePorts() =>
      client.print('/interface/bridge/port');

  Future<List<Map<String, String>>> bridgeVlans() =>
      client.print('/interface/bridge/vlan');

  Future<List<Map<String, String>>> bridgeHosts() =>
      client.print('/interface/bridge/host');

  Future<void> setBridgeVlanFiltering(String id, bool enabled) =>
      set('/interface/bridge', id, {'vlan-filtering': enabled ? 'yes' : 'no'});

  Future<List<Map<String, String>>> interfaceLists() =>
      client.print('/interface/list');

  Future<List<Map<String, String>>> interfaceListMembers() =>
      client.print('/interface/list/member');

  Future<List<Map<String, String>>> wireless() =>
      client.print('/interface/wireless');

  Future<Map<String, int>> wifiBackendInventory() async {
    var modern = 0;
    var legacy = 0;
    try {
      modern = (await client.print('/interface/wifi')).length;
    } catch (_) {}
    try {
      legacy = (await client.print('/interface/wireless')).length;
    } catch (_) {}
    return {'modern': modern, 'legacy': legacy};
  }

  Future<List<Map<String, String>>> wirelessInterfacesAll() async {
    final result = <Map<String, String>>[];
    try {
      final rows = await client.print('/interface/wifi');
      for (final row in rows) {
        result.add({...row, '_backend': 'WiFi', '_path': '/interface/wifi'});
      }
    } catch (_) {}
    try {
      final rows = await client.print('/interface/wireless');
      for (final row in rows) {
        result.add({
          ...row,
          '_backend': 'Wireless',
          '_path': '/interface/wireless',
        });
      }
    } catch (_) {}
    return result;
  }

  Future<List<Map<String, String>>> wirelessRegistrationsAll() async {
    final result = <Map<String, String>>[];
    try {
      final rows = await client.print('/interface/wifi/registration-table');
      for (final row in rows) {
        result.add({
          ...row,
          '_backend': 'WiFi',
          '_path': '/interface/wifi/registration-table',
        });
      }
    } catch (_) {}
    try {
      final rows = await client.print('/interface/wireless/registration-table');
      for (final row in rows) {
        result.add({
          ...row,
          '_backend': 'Wireless',
          '_path': '/interface/wireless/registration-table',
        });
      }
    } catch (_) {}
    return result;
  }

  Future<List<Map<String, String>>> wirelessSecurityProfilesAll() async {
    final result = <Map<String, String>>[];
    try {
      final rows = await client.print('/interface/wifi/security');
      for (final row in rows) {
        result.add({...row, '_backend': 'WiFi'});
      }
    } catch (_) {}
    try {
      final rows = await client.print('/interface/wireless/security-profiles');
      for (final row in rows) {
        result.add({...row, '_backend': 'Wireless'});
      }
    } catch (_) {}
    return result;
  }

  Future<List<Map<String, String>>> scanWirelessInterface(
    String path,
    String id,
  ) async {
    try {
      return await client.collect(
        '$path/scan',
        arguments: ['=.id=$id', '=duration=5s'],
      );
    } catch (_) {
      return client.collect(
        '$path/scan',
        arguments: ['=numbers=$id', '=duration=5s'],
      );
    }
  }

  // FIREWALL / QUEUES
  Future<List<Map<String, String>>> firewallFilter() =>
      client.print('/ip/firewall/filter');
  Future<List<Map<String, String>>> firewallNat() =>
      client.print('/ip/firewall/nat');
  Future<List<Map<String, String>>> simpleQueues() =>
      client.print('/queue/simple');

  Future<List<Map<String, String>>> queueTree() => client.print('/queue/tree');

  Future<List<Map<String, String>>> queueTypes() => client.print('/queue/type');

  Future<void> resetQueueCounters(String path, String id) async {
    final reply = await client.command(['$path/reset-counters', '=.id=$id']);
    _throwIfError(reply);
  }

  // VPN DISCOVERY
  Future<List<Map<String, String>>> wireGuardInterfaces() =>
      client.print('/interface/wireguard');

  Future<List<Map<String, String>>> wireGuardPeers() =>
      client.print('/interface/wireguard/peers');

  Future<List<Map<String, String>>> wireGuardPeersByInterface(
    String interfaceName,
  ) async {
    final rows = await wireGuardPeers();
    return rows.where((e) => (e['interface'] ?? '') == interfaceName).toList();
  }

  Future<List<Map<String, String>>> zeroTierInterfaces() =>
      client.print('/zerotier/interface');

  Future<Map<String, List<Map<String, String>>>> vpnProtocolInventory() async {
    final paths = <String, String>{
      'WireGuard': '/interface/wireguard',
      'ZeroTier': '/zerotier/interface',
      'IPsec active peers': '/ip/ipsec/active-peers',
      'L2TP clients': '/interface/l2tp-client',
      'SSTP clients': '/interface/sstp-client',
      'OpenVPN clients': '/interface/ovpn-client',
    };
    final result = <String, List<Map<String, String>>>{};
    for (final entry in paths.entries) {
      try {
        result[entry.key] = await client.print(entry.value);
      } catch (_) {
        result[entry.key] = <Map<String, String>>[];
      }
    }
    return result;
  }

  Future<Map<String, String>> backToHomeStatus() => client.first('/ip/cloud');

  Future<List<Map<String, String>>> backToHomeUsers() async {
    try {
      return await client.print('/ip/cloud/back-to-home-user');
    } catch (_) {
      // Compatibility fallback for older/variant menu naming.
      try {
        return await client.print('/ip/cloud/back-to-home-users');
      } catch (_) {
        return <Map<String, String>>[];
      }
    }
  }

  Future<List<Map<String, String>>> ipAddresses() =>
      client.print('/ip/address');

  Future<List<Map<String, String>>> ipRoutes() => client.print('/ip/route');

  Future<List<Map<String, String>>> routingRoutesDetailed() =>
      client.print('/routing/route');

  Future<List<Map<String, String>>> routingTables() async {
    try {
      return await client.print('/routing/table');
    } catch (_) {
      return <Map<String, String>>[];
    }
  }

  Future<List<Map<String, String>>> arpEntries() => client.print('/ip/arp');

  // DISCOVERY / ROMON / TRAFFIC
  Future<List<Map<String, String>>> neighbors() => client.print('/ip/neighbor');

  Future<Map<String, String>> romonStatus() => client.first('/tool/romon');

  Future<List<Map<String, String>>> romonPorts() =>
      client.print('/tool/romon/port');

  Future<List<Map<String, String>>> romonDiscover() async {
    try {
      return await client.print('/tool/romon/discover');
    } catch (_) {
      return <Map<String, String>>[];
    }
  }

  Future<void> setRomonEnabled(bool enabled) async {
    final reply = await client.command([
      '/tool/romon/set',
      '=enabled=${enabled ? 'yes' : 'no'}',
    ]);
    _throwIfError(reply);
  }

  Future<Map<String, String>> interfaceTrafficOnce(String interfaceName) async {
    final rows = await client.collect(
      '/interface/monitor-traffic',
      arguments: ['=interface=$interfaceName', '=once='],
    );
    return rows.isEmpty ? <String, String>{} : rows.first;
  }

  // HOTSPOT ADVANCED
  Future<void> disconnectHotspotActive(String id) async {
    final rows = await client.print('/ip/hotspot/active', where: {'.id': id});

    final user = rows.isEmpty ? '' : (rows.first['user'] ?? '');

    if (user.isNotEmpty) {
      final cookies = await client.print(
        '/ip/hotspot/cookie',
        where: {'user': user},
      );
      for (final cookie in cookies) {
        final cookieId = cookie['.id'];
        if (cookieId != null) {
          await remove('/ip/hotspot/cookie', cookieId);
        }
      }
    }

    await remove('/ip/hotspot/active', id);
  }

  Future<void> removeHotspotCookie(String id) =>
      remove('/ip/hotspot/cookie', id);

  Future<void> removeHotspotHost(String id) => remove('/ip/hotspot/host', id);

  Future<void> removeHotspotIpBindingWithRootMikroManagerCleanup(
    Map<String, String> binding,
  ) async {
    final id = binding['.id'];
    if (id == null) return;

    final mac = binding['mac-address'] ?? '';
    final address = binding['address'] ?? '';

    await remove('/ip/hotspot/ip-binding', id);

    if (mac.isNotEmpty) {
      final queues = await client.print('/queue/simple', where: {'name': mac});
      for (final row in queues) {
        final rowId = row['.id'];
        if (rowId != null) {
          await remove('/queue/simple', rowId);
        }
      }

      final schedulers = await client.print(
        '/system/scheduler',
        where: {'name': mac},
      );
      for (final row in schedulers) {
        final rowId = row['.id'];
        if (rowId != null) {
          await remove('/system/scheduler', rowId);
        }
      }
    }

    if (address.isNotEmpty) {
      final arpRows = await client.print(
        '/ip/arp',
        where: {'address': address},
      );
      for (final row in arpRows) {
        final rowId = row['.id'];
        if (rowId != null) {
          await remove('/ip/arp', rowId);
        }
      }

      final leases = await client.print(
        '/ip/dhcp-server/lease',
        where: {'address': address},
      );
      for (final row in leases) {
        final rowId = row['.id'];
        if (rowId != null) {
          await remove('/ip/dhcp-server/lease', rowId);
        }
      }
    }
  }

  Future<void> makeHotspotHostBinding(
    Map<String, String> host, {
    String type = 'bypassed',
    String? comment,
  }) async {
    final values = <String, String>{
      if ((host['mac-address'] ?? '').isNotEmpty)
        'mac-address': host['mac-address']!,
      if ((host['address'] ?? '').isNotEmpty) 'address': host['address']!,
      'type': type,
      if (comment != null && comment.trim().isNotEmpty)
        'comment': comment.trim(),
    };
    await add('/ip/hotspot/ip-binding', values);
  }

  Future<void> addHotspotIpBinding({
    String? macAddress,
    String? address,
    String? toAddress,
    String type = 'regular',
    String? comment,
  }) async {
    await add('/ip/hotspot/ip-binding', {
      if (macAddress != null && macAddress.trim().isNotEmpty)
        'mac-address': macAddress.trim(),
      if (address != null && address.trim().isNotEmpty)
        'address': address.trim(),
      if (toAddress != null && toAddress.trim().isNotEmpty)
        'to-address': toAddress.trim(),
      'type': type,
      if (comment != null && comment.trim().isNotEmpty)
        'comment': comment.trim(),
    });
  }

  Future<List<Map<String, String>>> firewallMangle() =>
      client.print('/ip/firewall/mangle');

  Future<List<Map<String, String>>> firewallAddressLists() =>
      client.print('/ip/firewall/address-list');

  Future<void> restoreRouterBackup({
    required String name,
    String password = '',
  }) async {
    final reply = await client.command([
      '/system/backup/load',
      '=name=$name',
      '=password=$password',
    ]);
    _throwIfError(reply);
  }

  // ROUTEROS FILES
  Future<List<Map<String, String>>> files() => client.print('/file');

  Future<void> removeFile(String id) => remove('/file', id);

  Map<String, String> routerTransportNotes() => const {
    'socket':
        'Transport principal RootMikroManager, ports personnalisés supportés.',
    'router_os_client':
        'À utiliser pour tags, commandes concurrentes et streams longs sur 8728/8729.',
    'http':
        'À utiliser pour RouterOS REST HTTPS et services HTTP, pas pour remplacer le protocole API socket.',
  };

  // SYSTEM
  Future<List<Map<String, String>>> scripts() => client.print('/system/script');

  Future<List<Map<String, String>>> systemHealth() async {
    try {
      return await client.print('/system/health');
    } catch (_) {
      return <Map<String, String>>[];
    }
  }

  Future<List<Map<String, String>>> systemPackages() =>
      client.print('/system/package');

  Future<Map<String, String>> packageUpdateStatus() async {
    try {
      return await client.first('/system/package/update');
    } catch (_) {
      return <String, String>{};
    }
  }

  Future<void> checkForUpdates() async {
    final reply = await client.command([
      '/system/package/update/check-for-updates',
    ]);
    _throwIfError(reply);
  }

  Future<void> installPackageUpdate() async {
    final reply = await client.command(['/system/package/update/install']);
    _throwIfError(reply);
  }

  Future<Map<String, String>> ntpClient() async {
    try {
      return await client.first('/system/ntp/client');
    } catch (_) {
      return <String, String>{};
    }
  }

  Future<void> setNtpClient({
    required bool enabled,
    required String mode,
    required String servers,
  }) async {
    final words = <String>[
      '/system/ntp/client/set',
      '=enabled=${enabled ? 'yes' : 'no'}',
      '=mode=$mode',
    ];
    if (servers.isNotEmpty) words.add('=servers=$servers');
    final reply = await client.command(words);
    _throwIfError(reply);
  }

  Future<List<Map<String, String>>> schedulers() =>
      client.print('/system/scheduler');

  Future<List<Map<String, String>>> rootmikromanagerSalesScripts({
    String? daySource,
    String? monthOwner,
  }) async {
    const reportFields = ['=.proplist=.id,name,comment,owner,source'];
    final rows = daySource != null && daySource.isNotEmpty
        ? await client.print(
            '/system/script',
            where: {'source': daySource},
            arguments: reportFields,
            idleTimeout: const Duration(seconds: 15),
            withoutTotalTimeout: true,
          )
        : monthOwner != null && monthOwner.isNotEmpty
        ? await client.print(
            '/system/script',
            where: {'owner': monthOwner},
            arguments: reportFields,
            idleTimeout: const Duration(seconds: 15),
            withoutTotalTimeout: true,
          )
        : await client.print(
            '/system/script',
            arguments: reportFields,
            idleTimeout: const Duration(seconds: 15),
            withoutTotalTimeout: true,
          );

    return rows.where((row) {
      final name = row['name'] ?? '';
      final marker = row['comment'] ?? '';

      // Current RootMikroManager records use the dedicated marker.
      // Historical compatible records are recognized structurally by
      // the report name format rather than by an old product label.
      return marker == RootMikroManagerMarkers.reportScriptComment ||
          name.contains('-|-');
    }).toList();
  }

  /// Dashboard totals only need the encoded record name and its marker.
  /// Never download executable script bodies just to compute revenue.
  Future<List<Map<String, String>>> salesSummaryRows() async {
    final rows = await client.print(
      '/system/script',
      arguments: const ['=.proplist=.id,name,comment'],
      idleTimeout: const Duration(seconds: 15),
      withoutTotalTimeout: true,
    );
    return rows
        .where(
          (row) =>
              row['comment'] == RootMikroManagerMarkers.reportScriptComment ||
              (row['name'] ?? '').contains('-|-'),
        )
        .toList();
  }

  Future<int> removeRootMikroManagerSalesScripts({
    String? daySource,
    String? monthOwner,
  }) async {
    final rows = await rootmikromanagerSalesScripts(
      daySource: daySource,
      monthOwner: monthOwner,
    );

    var removed = 0;
    for (final row in rows) {
      final id = row['.id'];
      final name = row['name'] ?? '';
      if (id == null || !name.contains('-|-')) continue;

      await remove('/system/script', id);
      removed++;
    }
    return removed;
  }

  Future<void> runSystemScript(String id) async {
    final reply = await client.command(['/system/script/run', '=.id=$id']);
    _throwIfError(reply);
  }

  Future<void> setSchedulerEnabled(String id, {required bool enabled}) =>
      enabled
      ? enable('/system/scheduler', id)
      : disable('/system/scheduler', id);
  Future<List<Map<String, String>>> logs() => client.print('/log');

  Future<List<Map<String, String>>> logsForBuffer(String buffer) =>
      client.print('/log', where: {'buffer': buffer});

  Future<List<Map<String, String>>> loggingRules() =>
      client.print('/system/logging');

  Future<List<Map<String, String>>> loggingActions() =>
      client.print('/system/logging/action');

  Future<void> clearMemoryLogAction(String actionName) async {
    final reply = await client.command([
      '/system/logging/action/clear',
      '=action=$actionName',
    ]);
    _throwIfError(reply);
  }

  Future<int> clearAllMemoryLogs() async {
    final actions = await loggingActions();
    final names = actions
        .where((row) => row['target'] == 'memory')
        .map((row) => row['name'] ?? '')
        .where((name) => name.isNotEmpty)
        .toSet();
    for (final name in names) {
      await clearMemoryLogAction(name);
    }
    return names.length;
  }

  /// Changes RouterOS' built-in memory buffer. This is persisted by RouterOS.
  Future<void> setDefaultMemoryLogLines(int lines) async {
    if (lines < 1) throw ArgumentError.value(lines, 'lines');
    final actions = await loggingActions();
    Map<String, String>? memory;
    for (final row in actions) {
      if (row['name'] == 'memory' && row['target'] == 'memory') {
        memory = row;
        break;
      }
    }
    final id = memory?['.id'];
    if (id == null || id.isEmpty) {
      throw StateError('Action mémoire RouterOS introuvable.');
    }
    await set('/system/logging/action', id, {'memory-lines': '$lines'});
  }

  Future<void> limitDefaultMemoryLogsTo200() => setDefaultMemoryLogLines(200);

  /// Removes RootMikroManager's 200-line limit by restoring RouterOS' usual
  /// built-in memory buffer size. RouterOS does not support an infinite buffer.
  Future<void> disableDefaultMemoryLogLimit() => setDefaultMemoryLogLines(1000);

  Future<void> addHotspotUser({
    required String server,
    required String name,
    required String password,
    required String profile,
    required String comment,
    required String timeLimit,
    required int dataLimitBytes,
    bool enabled = true,
  }) {
    return add('/ip/hotspot/user', {
      'server': server,
      'name': name,
      'password': password,
      'profile': profile,
      'disabled': enabled ? 'no' : 'yes',
      'limit-uptime': timeLimit.trim().isEmpty ? '0' : timeLimit.trim(),
      'limit-bytes-total': dataLimitBytes.toString(),
      'comment': comment.trim(),
    });
  }

  Future<void> addPppSecret({
    required String name,
    required String password,
    required String profile,
    String service = 'pppoe',
    String? localAddress,
    String? remoteAddress,
    String? comment,
  }) {
    final values = <String, String>{
      'name': name,
      'password': password,
      'profile': profile,
      'service': service,
    };
    if (localAddress?.isNotEmpty == true) {
      values['local-address'] = localAddress!;
    }
    if (remoteAddress?.isNotEmpty == true) {
      values['remote-address'] = remoteAddress!;
    }
    if (comment?.isNotEmpty == true) values['comment'] = comment!;
    return add('/ppp/secret', values);
  }

  Future<void> addDhcpLease({
    required String address,
    required String macAddress,
    String? comment,
  }) {
    final values = <String, String>{
      'address': address,
      'mac-address': macAddress,
    };
    if (comment?.isNotEmpty == true) values['comment'] = comment!;
    return add('/ip/dhcp-server/lease', values);
  }

  Future<void> addDnsStatic({
    required String name,
    required String address,
    String? comment,
  }) {
    final values = <String, String>{'name': name, 'address': address};
    if (comment?.isNotEmpty == true) values['comment'] = comment!;
    return add('/ip/dns/static', values);
  }

  Future<void> addSimpleQueue({
    required String name,
    required String target,
    required String maxLimit,
    String? comment,
  }) {
    final values = <String, String>{
      'name': name,
      'target': target,
      'max-limit': maxLimit,
    };
    if (comment?.isNotEmpty == true) values['comment'] = comment!;
    return add('/queue/simple', values);
  }

  Future<void> add(String path, Map<String, String> values) async {
    final reply = await client.command([
      '$path/add',
      ...values.entries.map((e) => '=${e.key}=${e.value}'),
    ]);
    _throwIfError(reply);
  }

  Future<void> set(String path, String id, Map<String, String> values) async {
    final reply = await client.command([
      '$path/set',
      '=.id=$id',
      ...values.entries.map((e) => '=${e.key}=${e.value}'),
    ]);
    _throwIfError(reply);
  }

  Future<void> remove(String path, String id) async {
    final reply = await client.command(['$path/remove', '=.id=$id']);
    _throwIfError(reply);
  }

  Future<void> enable(String path, String id) async {
    final reply = await client.command(['$path/enable', '=.id=$id']);
    if (reply.type == '!trap') {
      await set(path, id, {'disabled': 'no'});
      return;
    }
    _throwIfError(reply);
  }

  Future<void> disable(String path, String id) async {
    final reply = await client.command(['$path/disable', '=.id=$id']);
    if (reply.type == '!trap') {
      await set(path, id, {'disabled': 'yes'});
      return;
    }
    _throwIfError(reply);
  }

  Future<List<Map<String, String>>> ping(String address, {int count = 4}) {
    return client.collect(
      '/ping',
      arguments: ['=address=$address', '=count=$count'],
    );
  }

  Future<List<Map<String, String>>> traceroute(String address) {
    return client.collect('/tool/traceroute', arguments: ['=address=$address']);
  }

  Future<List<Map<String, String>>> pingAdvanced({
    required String address,
    int count = 5,
    int size = 56,
    String interval = '1s',
    String srcAddress = '',
    String routingTable = '',
  }) {
    return client.collect(
      '/ping',
      arguments: [
        '=address=$address',
        '=count=$count',
        '=size=$size',
        if (interval.isNotEmpty) '=interval=$interval',
        if (srcAddress.isNotEmpty) '=src-address=$srcAddress',
        if (routingTable.isNotEmpty) '=routing-table=$routingTable',
      ],
    );
  }

  Future<List<Map<String, String>>> tracerouteAdvanced(
    String address, {
    int maxHops = 30,
  }) {
    return client.collect(
      '/tool/traceroute',
      arguments: ['=address=$address', '=max-hops=$maxHops'],
    );
  }

  Future<List<Map<String, String>>> torchOnce(String interfaceName) {
    return client.collect(
      '/tool/torch',
      arguments: ['=interface=$interfaceName', '=duration=5s'],
    );
  }

  Future<List<Map<String, String>>> bandwidthTest({
    required String address,
    required String protocol,
    required String direction,
    required String duration,
    String user = '',
    String password = '',
    String localTxSpeed = '',
    String remoteTxSpeed = '',
  }) {
    return client.collect(
      '/tool/bandwidth-test',
      arguments: [
        '=address=$address',
        '=protocol=$protocol',
        '=direction=$direction',
        '=duration=$duration',
        if (user.isNotEmpty) '=user=$user',
        if (password.isNotEmpty) '=password=$password',
        if (localTxSpeed.isNotEmpty) '=local-tx-speed=$localTxSpeed',
        if (remoteTxSpeed.isNotEmpty) '=remote-tx-speed=$remoteTxSpeed',
      ],
    );
  }

  Future<Map<String, String>> bandwidthServer() async {
    try {
      return await client.first('/tool/bandwidth-server');
    } catch (_) {
      return <String, String>{};
    }
  }

  Future<Map<String, String>> deviceMode() async {
    try {
      return await client.first('/system/device-mode');
    } catch (_) {
      return <String, String>{};
    }
  }

  Future<Map<String, String>> snifferSettings() async {
    try {
      return await client.first('/tool/sniffer');
    } catch (_) {
      return <String, String>{};
    }
  }

  Future<void> startSniffer({
    required String interfaceName,
    required String fileName,
    String ipFilter = '',
  }) async {
    final settings = <String>[
      '/tool/sniffer/set',
      '=filter-interface=$interfaceName',
      if (fileName.isNotEmpty) '=file-name=$fileName',
      if (ipFilter.isNotEmpty) '=filter-ip-address=$ipFilter',
    ];
    _throwIfError(await client.command(settings));
    _throwIfError(await client.command(['/tool/sniffer/start']));
  }

  Future<void> stopSniffer() async {
    _throwIfError(await client.command(['/tool/sniffer/stop']));
  }

  Future<void> createRouterBackup(String name) async {
    await createRouterBackupAdvanced(name: name);
  }

  Future<void> createRouterBackupAdvanced({
    required String name,
    String password = '',
  }) async {
    final words = <String>['/system/backup/save', '=name=$name'];
    if (password.isNotEmpty) {
      words.add('=password=$password');
    }
    final reply = await client.command(words);
    _throwIfError(reply);
  }

  Future<void> exportRouterConfig(String name) async {
    final reply = await client.command(['/export', '=file=$name']);
    _throwIfError(reply);
  }

  Future<void> reboot() async {
    try {
      final reply = await client.command(['/system/reboot']);
      _throwIfError(reply);
    } on RouterOsException catch (error) {
      if (!error.message.toLowerCase().contains('connexion fermée')) rethrow;
    }
  }

  Future<void> shutdown() async {
    try {
      final reply = await client.command(['/system/shutdown']);
      _throwIfError(reply);
    } on RouterOsException catch (error) {
      if (!error.message.toLowerCase().contains('connexion fermée')) rethrow;
    }
  }

  void _throwIfError(RouterOsReply reply) {
    if (reply.type == '!trap' || reply.type == '!fatal') {
      throw RouterOsException(reply.data['message'] ?? 'Erreur RouterOS');
    }
  }

  Future<void> close() => client.close();

  Future<List<Map<String, String>>> wifiInterfacesFor(String backend) async {
    try {
      return await client.print(
        backend == 'modern' ? '/interface/wifi' : '/interface/wireless',
      );
    } catch (_) {
      return <Map<String, String>>[];
    }
  }

  Future<List<Map<String, String>>> wifiAccessList(String backend) async {
    try {
      return await client.print(
        backend == 'modern'
            ? '/interface/wifi/access-list'
            : '/interface/wireless/access-list',
      );
    } catch (_) {
      return <Map<String, String>>[];
    }
  }

  Future<List<Map<String, String>>> legacyWirelessConnectList() async {
    try {
      return await client.print('/interface/wireless/connect-list');
    } catch (_) {
      return <Map<String, String>>[];
    }
  }

  Future<List<Map<String, String>>> wifiConfigurations() async {
    try {
      return await client.print('/interface/wifi/configuration');
    } catch (_) {
      return <Map<String, String>>[];
    }
  }

  Future<List<Map<String, String>>> wifiChannels() async {
    try {
      return await client.print('/interface/wifi/channel');
    } catch (_) {
      return <Map<String, String>>[];
    }
  }

  Future<List<Map<String, String>>> wifiSecurityProfilesModern() async {
    try {
      return await client.print('/interface/wifi/security');
    } catch (_) {
      return <Map<String, String>>[];
    }
  }

  Future<List<Map<String, String>>> wifiDatapaths() async {
    try {
      return await client.print('/interface/wifi/datapath');
    } catch (_) {
      return <Map<String, String>>[];
    }
  }

  Future<List<Map<String, String>>> wifiRemoteCaps() async {
    try {
      return await client.print('/interface/wifi/capsman/remote-cap');
    } catch (_) {
      return <Map<String, String>>[];
    }
  }

  Future<List<Map<String, String>>> wifiProvisioning() async {
    try {
      return await client.print('/interface/wifi/provisioning');
    } catch (_) {
      return <Map<String, String>>[];
    }
  }

  Future<List<Map<String, String>>> routingTablesAdvanced() async {
    try {
      return await client.print('/routing/table');
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, String>>> routingRules() async {
    try {
      return await client.print('/routing/rule');
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, String>>> ipVrfs() async {
    try {
      return await client.print('/ip/vrf');
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, String>>> ipv6Addresses() async {
    try {
      return await client.print('/ipv6/address');
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, String>>> ipv6Routes() async {
    try {
      return await client.print('/ipv6/route');
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, String>>> ipv6Neighbors() async {
    try {
      return await client.print('/ipv6/neighbor');
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, String>>> ipv6NdProfiles() async {
    try {
      return await client.print('/ipv6/nd');
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, String>>> bridgePortsAdvanced() async {
    try {
      return await client.print('/interface/bridge/port');
    } catch (_) {
      return [];
    }
  }

  Future<bool> scriptNameExists(String name, {String? exceptId}) async {
    final rows = await scripts();
    return rows.any((row) => row['name'] == name && row['.id'] != exceptId);
  }

  Future<void> runSystemScriptAdvanced(
    String id, {
    bool useScriptPermissions = false,
  }) async {
    final words = <String>[
      '/system/script/run',
      '=.id=$id',
      if (useScriptPermissions) '=use-script-permissions=yes',
    ];
    final reply = await client.command(words);
    _throwIfError(reply);
  }

  Future<List<Map<String, String>>> scriptJobs() async {
    try {
      return await client.print('/system/script/job');
    } catch (_) {
      return <Map<String, String>>[];
    }
  }

  Future<void> stopScriptJob(String id) async {
    final reply = await client.command([
      '/system/script/job/remove',
      '=.id=$id',
    ]);
    _throwIfError(reply);
  }

  Future<List<Map<String, String>>> scriptRelatedLogs(String scriptName) async {
    final rows = await logs();
    return rows.where((row) {
      final topics = (row['topics'] ?? '').toLowerCase();
      final message = (row['message'] ?? '').toLowerCase();
      return topics.contains('script') ||
          (scriptName.isNotEmpty && message.contains(scriptName.toLowerCase()));
    }).toList();
  }

  Future<List<Map<String, String>>> zeroTierPeers() async {
    try {
      return await client.print('/zerotier/peer');
    } catch (_) {
      return <Map<String, String>>[];
    }
  }

  Future<Map<String, String>> ipCloudStatus() async {
    final rows = await client.print('/ip/cloud');
    return rows.isEmpty ? <String, String>{} : rows.first;
  }
}
