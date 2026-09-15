import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/core/routeros/router_session.dart';
import 'package:root_mikro_manager/data/models/router_model.dart';

void main() {
  final session = RouterSession.instance;
  late ServerSocket server;
  late RouterModel router;
  final sockets = <Socket>[];
  var connections = 0;
  var logins = 0;
  var mutations = 0;
  final scriptRequests = <List<String>>[];
  const secret = ' @P@ss=é! ';

  setUp(() async {
    connections = logins = mutations = 0;
    scriptRequests.clear();
    server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    router = RouterModel(
      id: 1,
      name: 'Mock',
      host: '127.0.0.1',
      port: server.port,
      username: 'admin',
    );
    server.listen((socket) {
      sockets.add(socket);
      connections++;
      final buffer = <int>[];
      final words = <String>[];
      socket.listen((data) {
        buffer.addAll(data);
        while (buffer.isNotEmpty && buffer.length >= buffer.first + 1) {
          final count = buffer.first;
          final word = utf8.decode(buffer.sublist(1, count + 1));
          buffer.removeRange(0, count + 1);
          if (count != 0) {
            words.add(word);
            continue;
          }
          if (words.first == '/login') {
            logins++;
            expect(words, contains('=password=$secret'));
          }
          if (words.first == '/system/script/print') {
            scriptRequests.add(List.of(words));
          }
          if (words.first == '/test/fail') {
            socket.destroy();
          } else if (words.first == '/test/add') {
            mutations++;
            socket.destroy();
          } else {
            socket.add([5, ...utf8.encode('!done'), 0]);
          }
          words.clear();
        }
      }, onError: (_) {});
    });
    await session.connect(router, secret);
    session.registerActiveRouter(router, secret);
  });
  tearDown(() async {
    await session.disconnect();
    for (final socket in sockets) {
      socket.destroy();
    }
    sockets.clear();
    await server.close();
  });

  test('reuses live connection for opening and commands', () async {
    await session.connect(router, secret);
    await session.service.identity();
    await session.service.resource();
    expect(connections, 1);
    expect(logins, 1);
  });
  test(
    'isolated revenue query excludes script bodies and keeps main socket',
    () async {
      await session.readIsolated((reader) => reader.salesSummaryRows());
      expect(scriptRequests.single, [
        '/system/script/print',
        '=.proplist=.id,name,comment',
      ]);
      expect(connections, 2);
      await session.service.identity();
      expect(connections, 2);
      expect(session.connected, isTrue);
    },
  );
  test(
    'broken isolated socket does not disconnect interactive session',
    () async {
      await expectLater(
        session.readIsolated((reader) => reader.client.command(['/test/fail'])),
        throwsException,
      );
      expect(session.connected, isTrue);
      await session.service.identity();
      expect(connections, 2);
    },
  );
  test('concurrent commands coalesce recovery into one login', () async {
    await session.service.client.close();
    await Future.wait([
      session.service.identity(),
      session.service.resource(),
      session.service.systemClock(),
    ]);
    expect(connections, 2);
    expect(logins, 2);
    expect(session.connected, isTrue);
  });
  test('failed mutation is never replayed; next command reconnects', () async {
    await expectLater(
      session.service.client.command(['/test/add']),
      throwsException,
    );
    expect(mutations, 1);
    await session.service.identity();
    expect(connections, 2);
    expect(mutations, 1);
  });
  test('explicit disconnect does not reopen on next command', () async {
    await session.disconnect();
    await expectLater(session.service.identity(), throwsException);
    expect(connections, 1);
  });
}
