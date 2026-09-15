import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/router_model.dart';
import 'routeros_client.dart';
import 'routeros_service.dart';

enum RouterSessionStatus { disconnected, online, reconnecting, authError }

/// Session unique partagée par les écrans après connexion.
///
/// Le mot de passe actif est conservé uniquement en mémoire pour permettre
/// l'ouverture d'un second socket de monitoring. La persistance reste assurée
/// séparément par flutter_secure_storage.
class RouterSession {
  RouterSession._();

  static final instance = RouterSession._();

  final RouterOsService service = RouterOsService();
  final status = ValueNotifier(RouterSessionStatus.disconnected);
  Future<void>? _opening;
  Timer? _heartbeat;
  Future<void>? _maintenance;
  int _generation = 0;
  bool _allowSelfSigned = false;

  RouterModel? activeRouter;
  String? _activePassword;

  bool get connected =>
      activeRouter != null &&
      status.value == RouterSessionStatus.online &&
      service.client.isConnected;
  bool get hasStreamingCredentials =>
      activeRouter != null && (_activePassword ?? '').isNotEmpty;

  String? get activePassword => _activePassword;

  /// Isolate a slow read from the shared interactive socket. The operation
  /// owns this client and cannot close the active session on timeout.
  Future<T> readIsolated<T>(Future<T> Function(RouterOsService) read) async {
    final router = activeRouter;
    final password = _activePassword;
    final generation = _generation;
    final allowSelfSigned = _allowSelfSigned;
    if (router == null || password == null) {
      throw RouterOsException('Aucun routeur sélectionné');
    }
    final isolated = RouterOsService();
    try {
      await isolated.connect(
        router,
        password,
        allowSelfSignedCertificate: allowSelfSigned,
      );
      if (generation != _generation) {
        throw RouterOsException('Session changée : lecture annulée');
      }
      final result = await read(isolated);
      if (generation != _generation) {
        throw RouterOsException('Session changée : lecture annulée');
      }
      return result;
    } finally {
      await isolated.client.close();
    }
  }

  Future<void> connect(
    RouterModel router,
    String password, {
    bool allowSelfSignedCertificate = false,
  }) async {
    if (connected &&
        activeRouter?.id == router.id &&
        activeRouter?.host == router.host &&
        activeRouter?.port == router.port &&
        activeRouter?.username == router.username &&
        activeRouter?.useTls == router.useTls &&
        _activePassword == password &&
        _allowSelfSigned == allowSelfSignedCertificate) {
      return;
    }
    clearActiveRouter();
    final pending = _maintenance;
    if (pending != null) await pending;
    try {
      await _opening;
    } catch (_) {}
    _allowSelfSigned = allowSelfSignedCertificate;
    await service.connect(
      router,
      password,
      allowSelfSignedCertificate: allowSelfSignedCertificate,
    );
  }

  void registerActiveRouter(RouterModel router, String password) {
    activeRouter = router;
    _activePassword = password;
    status.value = RouterSessionStatus.online;
    service.client.ensureConnected = ensureConnected;
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_maintenance != null) return;
      _maintenance = _checkSession().whenComplete(() => _maintenance = null);
    });
  }

  /// Reuse the live client; coalesce concurrent reopen requests, like the
  /// reference connection pool. Never replay a command that already failed.
  Future<void> ensureConnected() async {
    final pending = _opening;
    if (pending != null) return pending;
    if (status.value == RouterSessionStatus.authError) {
      throw RouterOsAuthenticationException();
    }
    if (service.isConnected) return;
    final router = activeRouter;
    final password = _activePassword;
    if (router == null || password == null) {
      throw RouterOsException('Aucun routeur sélectionné');
    }
    final generation = _generation;
    final opening = () async {
      status.value = RouterSessionStatus.reconnecting;
      try {
        await service.connect(
          router,
          password,
          allowSelfSignedCertificate: _allowSelfSigned,
        );
        if (generation != _generation) {
          await service.client.close();
          throw RouterOsException('Session changée : connexion annulée');
        }
        status.value = RouterSessionStatus.online;
      } on RouterOsAuthenticationException {
        if (generation == _generation) {
          status.value = RouterSessionStatus.authError;
        }
        rethrow;
      } catch (_) {
        if (generation == _generation) {
          status.value = RouterSessionStatus.disconnected;
        }
        rethrow;
      }
    }();
    _opening = opening;
    try {
      await opening;
    } finally {
      if (identical(_opening, opening)) _opening = null;
    }
  }

  Future<void> _checkSession() async {
    if (activeRouter == null || status.value == RouterSessionStatus.authError) {
      return;
    }
    try {
      await ensureConnected();
      await service.identity();
    } catch (_) {
      if (activeRouter != null &&
          status.value != RouterSessionStatus.authError) {
        status.value = RouterSessionStatus.disconnected;
      }
      // Next command (or heartbeat) can reopen; no long retry loop blocks UI.
    }
  }

  void clearActiveRouter() {
    _generation++;
    service.client.invalidateSession();
    _heartbeat?.cancel();
    _heartbeat = null;
    status.value = RouterSessionStatus.disconnected;
    activeRouter = null;
    _activePassword = null;
    service.client.ensureConnected = null;
  }

  Future<void> disconnect() async {
    clearActiveRouter();
    final pending = _maintenance;
    if (pending != null) await pending;
    try {
      await _opening;
    } catch (_) {}
    await service.client.close();
  }
}
