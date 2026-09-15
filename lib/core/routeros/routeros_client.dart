import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' show BytesBuilder;

class RouterOsException implements Exception {
  final String message;
  RouterOsException(this.message);
  @override
  String toString() => message;
}

class RouterOsAuthenticationException extends RouterOsException {
  RouterOsAuthenticationException() : super('Identifiants RouterOS refusés');
}

class RouterOsReply {
  final String type;
  final Map<String, String> data;
  RouterOsReply(this.type, this.data);
}

class RouterOsClient {
  final Duration requestTimeout;
  RouterOsClient({this.requestTimeout = const Duration(seconds: 15)});
  Socket? _socket;
  bool _secureTransport = false;
  StreamSubscription<List<int>>? _subscription;
  final BytesBuilder _buffer = BytesBuilder(copy: false);
  final List<String> _sentence = [];
  final List<_Request> _requests = [];
  Future<void> _queue = Future.value();
  int _transportGeneration = 0;

  /// Session-owned connection cache, invoked before commands, never for login.
  Future<void> Function()? ensureConnected;
  int _sessionEpoch = 0;
  void invalidateSession() => _sessionEpoch++;

  bool get isConnected => _socket != null;
  bool get isSecure => _secureTransport;

  Future<void> connect(
    String host, {
    int port = 8728,
    Duration timeout = const Duration(seconds: 8),
    bool secure = false,
    bool allowBadCertificate = false,
  }) async {
    await close();
    _secureTransport = secure;

    if (secure) {
      _socket = await SecureSocket.connect(
        host,
        port,
        timeout: timeout,
        onBadCertificate: allowBadCertificate ? (_) => true : null,
      );
    } else {
      _socket = await Socket.connect(host, port, timeout: timeout);
    }

    final connectedSocket = _socket!;
    connectedSocket.setOption(SocketOption.tcpNoDelay, true);
    _subscription = connectedSocket.listen(
      _onData,
      onDone: () {
        if (identical(_socket, connectedSocket)) {
          _markDisconnected('Connexion fermée');
        }
      },
      onError: (Object e) {
        if (identical(_socket, connectedSocket)) {
          _markDisconnected('Connexion interrompue');
        }
      },
      cancelOnError: true,
    );
  }

  Future<void> login(String username, String password) async {
    final r = await _serialized(
      () => _commandNow(['/login', '=name=$username', '=password=$password']),
    );
    if (r.type == '!trap' || r.type == '!fatal') {
      throw RouterOsAuthenticationException();
    }
  }

  Future<List<Map<String, String>>> print(
    String path, {
    Map<String, String> where = const {},
    List<String> arguments = const [],
    Duration? totalTimeout,
    Duration? idleTimeout,
    bool withoutTotalTimeout = false,
  }) => collect(
    '$path/print',
    totalTimeout: totalTimeout,
    idleTimeout: idleTimeout,
    withoutTotalTimeout: withoutTotalTimeout,
    arguments: [
      ...arguments,
      ...where.entries.map((e) => '?${e.key}=${e.value}'),
    ],
  );

  Future<List<Map<String, String>>> collect(
    String commandPath, {
    List<String> arguments = const [],
    Duration? totalTimeout,
    Duration? idleTimeout,
    bool withoutTotalTimeout = false,
  }) => _withConnection(
    () => _serialized(() async {
      final rows = <Map<String, String>>[];
      final r = await _commandNow(
        [commandPath, ...arguments],
        onRe: rows.add,
        totalTimeout: totalTimeout,
        idleTimeout: idleTimeout,
        withoutTotalTimeout: withoutTotalTimeout,
      );
      _throwIfError(r, 'Erreur RouterOS');
      return rows;
    }),
  );

  Future<Map<String, String>> first(String path) async {
    final rows = await print(path);
    return rows.isEmpty ? <String, String>{} : rows.first;
  }

  /// Executes RouterOS `print count-only` without materialising result rows.
  Future<int> count(
    String path, {
    Map<String, String> where = const {},
    List<String> queries = const [],
    Duration? totalTimeout,
    Duration? idleTimeout,
    bool withoutTotalTimeout = false,
  }) => _withConnection(
    () => _serialized(() async {
      final reply = await _commandNow(
        [
          '$path/print',
          '=count-only=',
          ...queries,
          ...where.entries.map((entry) => '?${entry.key}=${entry.value}'),
        ],
        totalTimeout: totalTimeout,
        idleTimeout: idleTimeout,
        withoutTotalTimeout: withoutTotalTimeout,
      );
      _throwIfError(reply, 'Comptage RouterOS impossible');
      return int.tryParse(reply.data['ret'] ?? '') ?? 0;
    }),
  );

  Future<RouterOsReply> command(List<String> words) =>
      _withConnection(() => _serialized(() => _commandNow(words)));

  Future<T> _withConnection<T>(Future<T> Function() operation) async {
    final epoch = _sessionEpoch;
    await ensureConnected?.call();
    if (epoch != _sessionEpoch) {
      throw RouterOsException('Session changée : commande annulée');
    }
    return operation();
  }

  Future<T> _serialized<T>(Future<T> Function() operation) {
    final c = Completer<T>();
    final generation = _transportGeneration;
    _queue = _queue.catchError((_) {}).then((_) async {
      try {
        if (generation != _transportGeneration) {
          throw RouterOsException('Session changée : commande annulée');
        }
        c.complete(await operation());
      } catch (e, st) {
        c.completeError(e, st);
      }
    });
    return c.future;
  }

  Future<RouterOsReply> _commandNow(
    List<String> words, {
    void Function(Map<String, String>)? onRe,
    Duration? totalTimeout,
    Duration? idleTimeout,
    bool withoutTotalTimeout = false,
  }) async {
    final socket = _socket;
    if (socket == null) throw RouterOsException('Routeur non connecté');
    final req = _Request(onRe);
    final totalLimit = totalTimeout ?? requestTimeout;
    Timer? idleTimer;
    void resetIdle() {
      idleTimer?.cancel();
      if (idleTimeout != null) {
        idleTimer = Timer(idleTimeout, () {
          if (!req.completer.isCompleted) {
            req.completer.completeError(TimeoutException('inactivité'));
          }
        });
      }
    }

    req.onActivity = resetIdle;
    _requests.add(req);
    try {
      final reply = withoutTotalTimeout
          ? req.completer.future
          : req.completer.future.timeout(
              totalLimit,
              onTimeout: () => throw TimeoutException('limite totale'),
            );
      resetIdle();
      for (final word in words) {
        socket.add(_encodeWord(word));
      }
      socket.add(_encodeWord(''));
      // Observe replies before flushing, including failures during the write.
      final writeAndReply = Future.wait<Object?>([
        socket.flush(),
        reply,
      ], eagerError: true);
      if (withoutTotalTimeout) {
        await writeAndReply;
      } else {
        await writeAndReply.timeout(
          totalLimit,
          onTimeout: () => throw TimeoutException('limite totale'),
        );
      }
      return await reply;
    } on TimeoutException catch (error) {
      _requests.remove(req);
      // Without tags a late reply must never be delivered to the next command.
      await close();
      throw RouterOsException(
        'Délai de réponse RouterOS dépassé '
        'sur ${words.first} (${error.message ?? 'attente'}, '
        '${req.rowsReceived} ligne(s), ${req.bytesReceived} octet(s) reçus). '
        'Réponse incomplète.',
      );
    } on SocketException {
      _requests.remove(req);
      await close();
      throw RouterOsException('Connexion perdue avec le routeur');
    } finally {
      idleTimer?.cancel();
      req.onActivity = null;
    }
  }

  void _onData(List<int> data) {
    if (_requests.isNotEmpty && data.isNotEmpty) {
      _requests.first.bytesReceived += data.length;
      _requests.first.onActivity?.call();
    }
    _buffer.add(data);
    final bytes = _buffer.toBytes();
    var pos = 0;
    while (true) {
      final d = _decodeLength(bytes, pos);
      if (d == null) break;
      final len = d.$1, hdr = d.$2;
      if (pos + hdr + len > bytes.length) break;
      final word = utf8.decode(
        bytes.sublist(pos + hdr, pos + hdr + len),
        allowMalformed: true,
      );
      pos += hdr + len;
      if (word.isEmpty) {
        _dispatchSentence();
      } else {
        _sentence.add(word);
      }
    }
    final rest = bytes.sublist(pos);
    _buffer.clear();
    if (rest.isNotEmpty) _buffer.add(rest);
  }

  void _dispatchSentence() {
    if (_sentence.isEmpty) return;
    final type = _sentence.first;
    final data = <String, String>{};
    for (final word in _sentence.skip(1)) {
      if (word.startsWith('=')) {
        final i = word.indexOf('=', 1);
        if (i > 1) data[word.substring(1, i)] = word.substring(i + 1);
      }
    }
    _sentence.clear();
    if (_requests.isEmpty) return;
    final req = _requests.first;
    if (type == '!re') {
      req.rowsReceived++;
      req.onRe?.call(data);
      return;
    }
    if (type == '!trap') {
      req.failure = RouterOsReply(type, data);
      return;
    }
    if (type == '!done' || type == '!fatal') {
      _requests.removeAt(0);
      if (!req.completer.isCompleted) {
        req.completer.complete(req.failure ?? RouterOsReply(type, data));
      }
      if (type == '!fatal') {
        _markDisconnected('Connexion refusée par le routeur');
      }
    }
  }

  void _throwIfError(RouterOsReply r, String fallback) {
    if (r.type == '!trap' || r.type == '!fatal') {
      throw RouterOsException(r.data['message'] ?? fallback);
    }
  }

  void _failAll(String message) {
    for (final r in _requests) {
      if (!r.completer.isCompleted) {
        r.completer.completeError(RouterOsException(message));
      }
    }
    _requests.clear();
  }

  void _markDisconnected(String message) {
    _transportGeneration++;
    _socket?.destroy();
    _socket = null;
    _subscription = null;
    _failAll(message);
  }

  Future<void> close() async {
    _transportGeneration++;
    _failAll('Connexion fermée');
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;
    _buffer.clear();
    _sentence.clear();
  }

  List<int> _encodeWord(String word) {
    final payload = utf8.encode(word), n = payload.length;
    if (n < 0x80) return [n, ...payload];
    if (n < 0x4000) return [0x80 | (n >> 8), n & 0xff, ...payload];
    if (n < 0x200000) {
      return [0xc0 | (n >> 16), (n >> 8) & 0xff, n & 0xff, ...payload];
    }
    if (n < 0x10000000) {
      return [
        0xe0 | (n >> 24),
        (n >> 16) & 0xff,
        (n >> 8) & 0xff,
        n & 0xff,
        ...payload,
      ];
    }
    return [
      0xf0,
      (n >> 24) & 0xff,
      (n >> 16) & 0xff,
      (n >> 8) & 0xff,
      n & 0xff,
      ...payload,
    ];
  }

  (int, int)? _decodeLength(List<int> b, int p) {
    if (p >= b.length) return null;
    final x = b[p];
    if (x < 0x80) return (x, 1);
    if (x < 0xc0) {
      if (p + 1 >= b.length) return null;
      return (((x & 0x3f) << 8) | b[p + 1], 2);
    }
    if (x < 0xe0) {
      if (p + 2 >= b.length) return null;
      return (((x & 0x1f) << 16) | (b[p + 1] << 8) | b[p + 2], 3);
    }
    if (x < 0xf0) {
      if (p + 3 >= b.length) return null;
      return (
        ((x & 0x0f) << 24) | (b[p + 1] << 16) | (b[p + 2] << 8) | b[p + 3],
        4,
      );
    }
    if (x == 0xf0) {
      if (p + 4 >= b.length) return null;
      return (
        (b[p + 1] << 24) | (b[p + 2] << 16) | (b[p + 3] << 8) | b[p + 4],
        5,
      );
    }
    return null;
  }
}

class _Request {
  int rowsReceived = 0;
  int bytesReceived = 0;
  void Function()? onActivity;
  RouterOsReply? failure;
  final void Function(Map<String, String>)? onRe;
  final Completer<RouterOsReply> completer = Completer<RouterOsReply>();
  _Request(this.onRe);
}
