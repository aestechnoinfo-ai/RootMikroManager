import 'dart:async';

import 'package:router_os_client/router_os_client.dart' show TaggedCommand;

import 'package_routeros_client.dart';
import 'router_session.dart';

class RouterOsStreamingService {
  final PackageRouterOsClient _packageClient = PackageRouterOsClient();

  String? _activeTag;

  Future<void> connectFromSession() async {
    final session = RouterSession.instance;
    final router = session.activeRouter;
    final password = session.activePassword;

    if (router == null || password == null || password.isEmpty) {
      throw StateError(
        'Aucun identifiant de session disponible pour le monitoring.',
      );
    }

    await _packageClient.connect(
      host: router.host,
      port: router.port,
      username: router.username,
      password: password,
      useTls: router.useTls || router.port == 8729,
    );
  }

  Stream<Map<String, String>> monitorInterface(String interfaceName) async* {
    await _ensureConnected();
    final tag = _newTag('traffic');
    _activeTag = tag;

    yield* _packageClient.streamData('/interface/monitor-traffic', {
      'interface': interfaceName,
    }, tag);
  }

  Stream<Map<String, String>> torch(
    String interfaceName, {
    String? srcAddress,
    String? dstAddress,
    String? protocol,
    String? port,
  }) async* {
    await _ensureConnected();
    final tag = _newTag('torch');
    _activeTag = tag;

    final params = <String, String>{
      'interface': interfaceName,
      if ((srcAddress ?? '').trim().isNotEmpty)
        'src-address': srcAddress!.trim(),
      if ((dstAddress ?? '').trim().isNotEmpty)
        'dst-address': dstAddress!.trim(),
      if ((protocol ?? '').trim().isNotEmpty) 'protocol': protocol!.trim(),
      if ((port ?? '').trim().isNotEmpty) 'port': port!.trim(),
    };

    yield* _packageClient.streamData('/tool/torch', params, tag);
  }

  Stream<dynamic> parallelSnapshot() async* {
    await _ensureConnected();
    yield* _packageClient.talkMultiple([
      TaggedCommand(command: '/system/resource/print', tag: 'resource'),
      TaggedCommand(command: '/interface/print', tag: 'interfaces'),
      TaggedCommand(command: '/ip/address/print', tag: 'addresses'),
    ]);
  }

  Future<void> cancelActive() async {
    final tag = _activeTag;
    _activeTag = null;

    if (tag != null && _packageClient.connected) {
      try {
        await _packageClient.cancel(tag);
      } catch (_) {}
    }
  }

  Future<void> _ensureConnected() async {
    if (!_packageClient.connected) {
      await connectFromSession();
      return;
    }

    try {
      final alive = await _packageClient.isAlive();
      if (!alive) {
        _packageClient.close();
        await connectFromSession();
      }
    } catch (_) {
      _packageClient.close();
      await connectFromSession();
    }
  }

  String _newTag(String prefix) =>
      'rmm-$prefix-${DateTime.now().microsecondsSinceEpoch}';

  Future<void> close() async {
    await cancelActive();
    _packageClient.close();
  }
}
