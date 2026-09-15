import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class RouterOsRestException implements Exception {
  final String message;
  final int? statusCode;
  final Uri? uri;

  const RouterOsRestException(this.message, {this.statusCode, this.uri});

  @override
  String toString() {
    final code = statusCode == null ? '' : ' HTTP $statusCode';
    final target = uri == null ? '' : ' (${uri.toString()})';
    return 'RouterOsRestException$code: $message$target';
  }
}

class RouterOsRestClient {
  final String host;
  final int port;
  final String username;
  final String password;

  /// REST over HTTPS is the recommended mode.
  ///
  /// Important: TLS is NOT inferred only by "REST enabled". It is derived
  /// from the configured web service / port unless explicitly supplied.
  final bool useHttps;

  final bool allowSelfSignedCertificate;
  final Duration timeout;

  IOClient? _client;

  RouterOsRestClient({
    required this.host,
    required this.username,
    required this.password,
    int? port,
    bool? useHttps,
    this.allowSelfSignedCertificate = false,
    this.timeout = const Duration(seconds: 12),
  }) : port = port ?? ((useHttps ?? true) ? 443 : 80),
       useHttps = useHttps ?? ((port ?? 443) == 443);

  String get scheme => useHttps ? 'https' : 'http';

  Uri uriFor(String path, [Map<String, dynamic>? query]) {
    var cleanPath = path.trim();

    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      final parsed = Uri.parse(cleanPath);
      cleanPath = parsed.path;
    }

    cleanPath = cleanPath.replaceFirst(RegExp(r'^/+'), '');
    if (cleanPath.startsWith('rest/')) {
      cleanPath = cleanPath.substring(5);
    }

    final segments = <String>[
      'rest',
      ...cleanPath.split('/').where((segment) => segment.trim().isNotEmpty),
    ];

    return Uri(
      scheme: scheme,
      host: host,
      port: port,
      pathSegments: segments,
      queryParameters: query?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send('GET', uriFor(path, query));

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) =>
      _send('POST', uriFor(path), body: body);

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) =>
      _send('PUT', uriFor(path), body: body);

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) =>
      _send('PATCH', uriFor(path), body: body);

  Future<dynamic> delete(String path) => _send('DELETE', uriFor(path));

  Future<bool> ping() async {
    try {
      await get('system/resource');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<dynamic> _send(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    _validateProtocolPort(uri);

    final client = _client ??= _buildClient();
    final request = http.Request(method, uri)..headers.addAll(_headers());

    if (body != null) {
      request.body = jsonEncode(body);
    }

    try {
      final streamed = await client.send(request).timeout(timeout);
      final response = await http.Response.fromStream(
        streamed,
      ).timeout(timeout);

      dynamic decoded;
      if (response.body.trim().isEmpty) {
        decoded = const <dynamic>[];
      } else {
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {
          decoded = response.body;
        }
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message = 'REST request failed';
        if (decoded is Map) {
          final detail = decoded['detail'];
          final apiMessage = decoded['message'];
          if (apiMessage != null || detail != null) {
            message = [
              if (apiMessage != null) apiMessage.toString(),
              if (detail != null) detail.toString(),
            ].join(' — ');
          }
        } else if (decoded is String && decoded.isNotEmpty) {
          message = decoded;
        }

        throw RouterOsRestException(
          message,
          statusCode: response.statusCode,
          uri: uri,
        );
      }

      return decoded;
    } on HandshakeException catch (e) {
      throw RouterOsRestException(
        'Échec TLS/HTTPS. Vérifie www-ssl, le certificat RouterOS '
        'et l’option certificat auto-signé. Détail: $e',
        uri: uri,
      );
    } on SocketException catch (e) {
      throw RouterOsRestException(
        'Connexion réseau impossible vers '
        '${uri.scheme}://${uri.host}:${uri.port}. '
        'Vérifie le service RouterOS, le port, le VPN et le firewall. '
        'Détail: $e',
        uri: uri,
      );
    } on http.ClientException catch (e) {
      throw RouterOsRestException(_clientExceptionMessage(e, uri), uri: uri);
    }
  }

  Map<String, String> _headers() {
    final token = base64Encode(utf8.encode('$username:$password'));
    return {
      HttpHeaders.authorizationHeader: 'Basic $token',
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    };
  }

  IOClient _buildClient() {
    final io = HttpClient();

    if (allowSelfSignedCertificate && useHttps) {
      io.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    }

    return IOClient(io);
  }

  void _validateProtocolPort(Uri uri) {
    // Prevent the exact failure observed during previous tests:
    // http://router:443/rest/... causes the TLS service to close the
    // connection before an HTTP header is received.
    if (uri.scheme == 'http' && uri.port == 443) {
      throw RouterOsRestException(
        'Configuration REST incohérente : le port 443 attend HTTPS, '
        'mais la requête utilise HTTP. Utilise https:// sur 443.',
        uri: uri,
      );
    }

    if (uri.scheme == 'https' && uri.port == 80) {
      throw RouterOsRestException(
        'Configuration REST incohérente : le port 80 est normalement '
        'HTTP, mais la requête utilise HTTPS. Vérifie /ip service.',
        uri: uri,
      );
    }
  }

  String _clientExceptionMessage(http.ClientException error, Uri uri) {
    final lower = error.message.toLowerCase();

    if (lower.contains('closed before full header') ||
        lower.contains('connection closed')) {
      if (uri.port == 443 && uri.scheme == 'http') {
        return 'Le routeur a fermé la connexion car HTTP a été envoyé '
            'sur le port HTTPS 443. RootMikroManager doit utiliser '
            'https://${uri.host}:443/rest/...';
      }

      return 'Le serveur a fermé la connexion avant de renvoyer une '
          'réponse HTTP complète. Vérifie surtout le couple protocole/port '
          '(${uri.scheme}:${uri.port}), www/www-ssl, le certificat et le '
          'firewall.';
    }

    return 'Erreur HTTP REST: ${error.message}';
  }

  void close() {
    _client?.close();
    _client = null;
  }
}
