import 'dart:io';

import '../../core/routeros/routeros_service.dart';

class DiagnosticCheck {
  final String name;
  final bool ok;
  final String detail;

  const DiagnosticCheck({
    required this.name,
    required this.ok,
    required this.detail,
  });
}

class RouterDiagnosticsService {
  final RouterOsService service;

  const RouterDiagnosticsService(this.service);

  Future<List<DiagnosticCheck>> run({String? host, int? port}) async {
    final checks = <DiagnosticCheck>[];

    if (host != null && host.isNotEmpty && port != null) {
      try {
        final socket = await Socket.connect(
          host,
          port,
          timeout: const Duration(seconds: 3),
        );
        socket.destroy();
        checks.add(
          DiagnosticCheck(
            name: 'TCP $host:$port',
            ok: true,
            detail: 'Port joignable',
          ),
        );
      } catch (e) {
        checks.add(
          DiagnosticCheck(name: 'TCP $host:$port', ok: false, detail: '$e'),
        );
      }
    }

    try {
      final identity = await service.identity();
      checks.add(
        DiagnosticCheck(
          name: 'Session RouterOS',
          ok: true,
          detail: 'Identity : ${identity['name'] ?? '—'}',
        ),
      );
    } catch (e) {
      checks.add(
        DiagnosticCheck(name: 'Session RouterOS', ok: false, detail: '$e'),
      );
      return checks;
    }

    try {
      final resource = await service.resource();
      checks.add(
        DiagnosticCheck(
          name: 'Ressources',
          ok: true,
          detail:
              'RouterOS ${resource['version'] ?? '—'} • ${resource['board-name'] ?? '—'}',
        ),
      );
    } catch (e) {
      checks.add(DiagnosticCheck(name: 'Ressources', ok: false, detail: '$e'));
    }

    try {
      final clock = await service.systemClock();
      checks.add(
        DiagnosticCheck(
          name: 'Horloge',
          ok: clock.isNotEmpty,
          detail:
              '${clock['date'] ?? '—'} ${clock['time'] ?? '—'} ${clock['time-zone-name'] ?? ''}',
        ),
      );
    } catch (e) {
      checks.add(DiagnosticCheck(name: 'Horloge', ok: false, detail: '$e'));
    }

    try {
      final files = await service.files();
      checks.add(
        DiagnosticCheck(
          name: 'Accès fichiers',
          ok: true,
          detail: '${files.length} fichier(s) visible(s)',
        ),
      );
    } catch (e) {
      checks.add(
        DiagnosticCheck(name: 'Accès fichiers', ok: false, detail: '$e'),
      );
    }

    return checks;
  }
}
