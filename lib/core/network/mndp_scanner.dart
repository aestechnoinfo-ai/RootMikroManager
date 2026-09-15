import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Direct IPv4 UDP discovery, adapted from the reference project's scanner.
/// A scan owns its socket; cancellation closes it, even if no router replies.
class MndpScanner {
  const MndpScanner();

  Stream<Map<String, String>> scan({
    required Duration duration,
    Future<void>? cancelled,
  }) {
    late final StreamController<Map<String, String>> controller;
    RawDatagramSocket? socket;
    Timer? requestTimer;
    Timer? deadline;
    bool stopped = false;
    void stop() {
      if (stopped) return;
      stopped = true;
      requestTimer?.cancel();
      deadline?.cancel();
      socket?.close();
      unawaited(controller.close());
    }

    Future<void> start() async {
      cancelled?.then((_) => stop());
      try {
        final bound = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4,
          5678,
          reuseAddress: true,
        );
        if (stopped) {
          bound.close();
          return;
        }
        socket = bound;
        bound.broadcastEnabled = true;
        bound.listen(
          (event) {
            if (event != RawSocketEvent.read || stopped) return;
            Datagram? packet;
            while ((packet = bound.receive()) != null) {
              final row = decode(packet!.data, packet.address.address);
              if (row != null) controller.add(row);
            }
          },
          onError: (Object error, StackTrace stack) {
            if (!stopped) controller.addError(error, stack);
            stop();
          },
          onDone: stop,
        );
        void request() {
          try {
            bound.send(Uint8List(4), InternetAddress('255.255.255.255'), 5678);
          } on SocketException {
            // A transient interface change can recover on the next request.
          }
        }

        request();
        requestTimer = Timer.periodic(
          const Duration(seconds: 3),
          (_) => request(),
        );
        deadline = Timer(duration, stop);
      } catch (error, stack) {
        if (!stopped) controller.addError(error, stack);
        stop();
      }
    }

    controller = StreamController<Map<String, String>>(
      onListen: start,
      onCancel: stop,
    );
    return controller.stream;
  }

  /// Preserve the datagram source IPv4, as in the reference implementation.
  /// Missing identity is allowed; malformed TLVs are rejected atomically.
  static Map<String, String>? decode(Uint8List data, String sourceIp) {
    if (data.length < 8 ||
        InternetAddress.tryParse(sourceIp)?.type != InternetAddressType.IPv4) {
      return null;
    }
    final bytes = ByteData.sublistView(data);
    final row = <String, String>{'address': sourceIp};
    var offset = 4;
    while (offset < data.length) {
      if (offset + 4 > data.length) return null;
      final type = bytes.getUint16(offset);
      final length = bytes.getUint16(offset + 2);
      offset += 4;
      if (offset + length > data.length) return null;
      final value = data.sublist(offset, offset + length);
      offset += length;
      if (type == 1) {
        if (length != 6) return null;
        row['mac-address'] = value
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join(':')
            .toUpperCase();
      } else {
        final key = {
          5: 'identity',
          7: 'version',
          8: 'platform',
          12: 'board',
          16: 'interface',
        }[type];
        if (key == null) continue;
        try {
          row[key] = utf8.decode(value);
        } on FormatException {
          row[key] = latin1.decode(value);
        }
      }
    }
    return row.containsKey('mac-address') ? row : null;
  }
}
