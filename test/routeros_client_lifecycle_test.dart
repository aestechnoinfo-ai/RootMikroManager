import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/core/routeros/routeros_client.dart';

List<int> sentence(List<String> words) => [
  for (final word in words) ...[utf8.encode(word).length, ...utf8.encode(word)],
  0,
];

void main() {
  late ServerSocket server;
  late RouterOsClient client;
  final sockets = <Socket>[];

  setUp(() async {
    server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    client = RouterOsClient(requestTimeout: const Duration(milliseconds: 150));
  });

  tearDown(() async {
    await client.close();
    for (final socket in sockets) {
      socket.destroy();
    }
    sockets.clear();
    await server.close();
  });

  void respond(void Function(Socket socket, int index) handler) {
    server.listen((socket) {
      sockets.add(socket);
      final buffer = <int>[];
      var index = 0;
      socket.listen((bytes) {
        buffer.addAll(bytes);
        while (buffer.isNotEmpty) {
          final size = buffer.first;
          if (buffer.length < size + 1) break;
          buffer.removeRange(0, size + 1);
          if (size == 0) handler(socket, index++);
        }
      });
    });
  }

  test('trap is drained through done before the next request', () async {
    respond((socket, index) {
      if (index == 0) {
        socket.add(sentence(['!trap', '=message=denied']));
        socket.add(sentence(['!done']));
      } else {
        socket.add(sentence(['!re', '=name=expected']));
        socket.add(sentence(['!done']));
      }
    });
    await client.connect('127.0.0.1', port: server.port);
    await expectLater(
      client.first('/denied'),
      throwsA(isA<RouterOsException>()),
    );
    expect(await client.first('/system/identity'), {'name': 'expected'});
  });

  test(
    'long progressing read outlives default timeout and completes',
    () async {
      Timer? timer;
      addTearDown(() => timer?.cancel());
      respond((socket, _) {
        var index = 0;
        timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
          socket.add(sentence(['!re', '=name=row${index++}']));
          if (index == 4) {
            timer?.cancel();
            socket.add(sentence(['!done']));
          }
        });
      });
      await client.connect('127.0.0.1', port: server.port);
      final rows = await client.print(
        '/system/script',
        totalTimeout: const Duration(seconds: 3),
        idleTimeout: const Duration(seconds: 1),
      );
      expect(rows.length, 4);
      expect(client.isConnected, isTrue);
    },
  );

  test('sales-style read has no hard deadline while data progresses', () async {
    Timer? timer;
    addTearDown(() => timer?.cancel());
    respond((socket, _) {
      var index = 0;
      timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
        socket.add(sentence(['!re', '=name=sale${index++}']));
        if (index == 5) {
          timer?.cancel();
          socket.add(sentence(['!done']));
        }
      });
    });
    await client.connect('127.0.0.1', port: server.port);
    final rows = await client.print(
      '/system/script',
      idleTimeout: const Duration(milliseconds: 300),
      withoutTotalTimeout: true,
    );
    expect(rows.length, 5);
    expect(client.isConnected, isTrue);
  });

  test('silent read identifies command and zero progress', () async {
    respond((_, _) {});
    await client.connect('127.0.0.1', port: server.port);
    await expectLater(
      client.print(
        '/system/script',
        totalTimeout: const Duration(seconds: 3),
        idleTimeout: const Duration(milliseconds: 150),
      ),
      throwsA(
        isA<RouterOsException>()
            .having((e) => e.message, 'reason', contains('inactivité'))
            .having((e) => e.message, 'path', contains('/system/script/print'))
            .having(
              (e) => e.message,
              'progress',
              contains('0 ligne(s), 0 octet(s)'),
            ),
      ),
    );
    expect(client.isConnected, isFalse);
  });

  test(
    'continuous replies cannot bypass hard deadline or return partial totals',
    () async {
      Timer? timer;
      addTearDown(() => timer?.cancel());
      respond((socket, _) {
        socket.add(sentence(['!re', '=name=first']));
        timer = Timer.periodic(const Duration(milliseconds: 60), (_) {
          socket.add(sentence(['!re', '=name=more']));
        });
      });
      await client.connect('127.0.0.1', port: server.port);
      await expectLater(
        client.print(
          '/system/script',
          totalTimeout: const Duration(milliseconds: 350),
          idleTimeout: const Duration(seconds: 1),
        ),
        throwsA(
          isA<RouterOsException>().having(
            (e) => e.message,
            'reason',
            contains('limite totale'),
          ),
        ),
      );
      timer?.cancel();
      expect(client.isConnected, isFalse);
    },
  );

  test('complex password is transmitted unchanged as UTF-8', () async {
    const secret = ' @P@ss=:+/é!#&? ,.; ';
    final received = Completer<List<String>>();
    server.listen((socket) {
      sockets.add(socket);
      final bytes = <int>[];
      final words = <String>[];
      socket.listen((data) {
        bytes.addAll(data);
        while (bytes.isNotEmpty && bytes.length >= bytes.first + 1) {
          final length = bytes.first;
          final word = utf8.decode(bytes.sublist(1, length + 1));
          bytes.removeRange(0, length + 1);
          if (length == 0) {
            if (!received.isCompleted) received.complete(List.of(words));
            socket.add(sentence(['!done']));
          } else {
            words.add(word);
          }
        }
      });
    });
    await client.connect('127.0.0.1', port: server.port);
    await client.login('custom-user', secret);
    expect(await received.future, [
      '/login',
      '=name=custom-user',
      '=password=$secret',
    ]);
  });

  test('count-only returns ret without materialising rows', () async {
    final received = Completer<List<String>>();
    server.listen((socket) {
      sockets.add(socket);
      final bytes = <int>[];
      final words = <String>[];
      socket.listen((data) {
        bytes.addAll(data);
        while (bytes.isNotEmpty && bytes.length >= bytes.first + 1) {
          final length = bytes.first;
          final word = utf8.decode(bytes.sublist(1, length + 1));
          bytes.removeRange(0, length + 1);
          if (length == 0) {
            if (!received.isCompleted) received.complete(List.of(words));
            socket.add(sentence(['!done', '=ret=5000']));
          } else {
            words.add(word);
          }
        }
      });
    });
    await client.connect('127.0.0.1', port: server.port);
    final count = await client.count(
      '/ip/hotspot/user',
      queries: const ['?profile=3h'],
    );
    expect(count, 5000);
    expect(await received.future, [
      '/ip/hotspot/user/print',
      '=count-only=',
      '?profile=3h',
    ]);
  });

  test(
    'timeout closes the transport instead of reusing late responses',
    () async {
      respond((_, _) {});
      await client.connect('127.0.0.1', port: server.port);
      await expectLater(
        client.first('/silent'),
        throwsA(isA<RouterOsException>()),
      );
      expect(client.isConnected, isFalse);
    },
  );

  test('login refusal has a distinct authentication exception', () async {
    respond((socket, _) {
      socket.add(sentence(['!trap', '=message=invalid user name or password']));
      socket.add(sentence(['!done']));
    });
    await client.connect('127.0.0.1', port: server.port);
    await expectLater(
      client.login('test', 'not-a-real-password'),
      throwsA(isA<RouterOsAuthenticationException>()),
    );
  });

  test('remote closure clears connected state', () async {
    respond((socket, _) => socket.destroy());
    await client.connect('127.0.0.1', port: server.port);
    await expectLater(
      client.first('/closed'),
      throwsA(isA<RouterOsException>()),
    );
    expect(client.isConnected, isFalse);
  });
}
