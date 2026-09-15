import 'dart:io';
import 'dart:convert';
import 'package:mikrotik_mndp/decoder.dart';
import 'package:mikrotik_mndp/product_info_provider.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'package:flutter/services.dart';

class NetworkState {
  final bool wifi;
  final bool cellular;
  final bool vpn;
  final String vpnInterface;

  const NetworkState({
    required this.wifi,
    required this.cellular,
    required this.vpn,
    required this.vpnInterface,
  });

  factory NetworkState.fromMap(Map<Object?, Object?> map) => NetworkState(
    wifi: map['wifi'] == true,
    cellular: map['cellular'] == true,
    vpn: map['vpn'] == true,
    vpnInterface: map['vpnInterface']?.toString() ?? '',
  );
}

class NetworkBindingService {
  final NetworkInfo networkInfo = NetworkInfo();
  final MndpMessageDecoder decoder = MndpMessageDecoderImpl(
    MikrotikProductInfoProviderImpl(),
  );

  Future<String?> wifiIpv4() async {
    try {
      final address = await networkInfo.getWifiIP();
      final parsed = InternetAddress.tryParse(address ?? '');
      return parsed?.type == InternetAddressType.IPv4 ? address : null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>> decodeMndpRow(Map<String, String> row) async {
    final raw = row['raw'];
    if (raw == null) return row;
    try {
      final packet = await decoder.decode(base64Decode(raw));
      final mac = packet.macAddress?.trim().toUpperCase() ?? '';
      final identity = packet.identity?.trim() ?? '';
      final address = packet.unicastIpv4Address ?? row['address'] ?? '';
      if (!RegExp(r'^([0-9A-F]{2}:){5}[0-9A-F]{2}$').hasMatch(mac) ||
          identity.isEmpty ||
          InternetAddress.tryParse(address)?.type != InternetAddressType.IPv4) {
        return const {};
      }
      return {
        'mac-address': mac,
        'identity': identity,
        'address': address,
        'board': packet.boardName?.trim() ?? '',
        'version': packet.version ?? '',
        'interface': packet.interfaceName ?? '',
      };
    } catch (_) {
      return const {};
    }
  }

  static const _channel = MethodChannel('root_mikro_manager/network_binding');
  static const _mndpEvents = EventChannel(
    'root_mikro_manager/network_binding/mndp',
  );

  Future<NetworkState> state() async {
    if (!Platform.isAndroid) {
      return NetworkState(
        wifi: await wifiIpv4() != null,
        cellular: false,
        vpn: false,
        vpnInterface: '',
      );
    }
    final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
      'networkState',
    );
    return NetworkState.fromMap(raw ?? const {});
  }

  Future<bool> probeTcp(
    String host,
    int port, {
    required Duration timeout,
    bool bindVpn = false,
  }) async {
    if (!bindVpn || !Platform.isAndroid) {
      final socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();
      return true;
    }
    return await _channel.invokeMethod<bool>('probeTcp', {
          'host': host,
          'port': port,
          'timeoutMs': timeout.inMilliseconds,
          'bindVpn': bindVpn,
        }) ??
        false;
  }

  Future<List<Map<String, String>>> discoverMndp(Duration duration) async {
    if (!Platform.isAndroid) return const [];
    final raw = await _channel.invokeMethod<List<Object?>>('discoverMndp', {
      'durationMs': duration.inMilliseconds,
    });
    return (raw ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map(
          (row) => row.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ),
        )
        .toList();
  }

  Stream<Map<String, String>> discoverMndpStream(Duration duration) {
    if (!Platform.isAndroid) return const Stream.empty();
    return _mndpEvents
        .receiveBroadcastStream({'durationMs': duration.inMilliseconds})
        .where((event) => event is Map<Object?, Object?>)
        .cast<Map<Object?, Object?>>()
        .map(
          (row) => row.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ),
        )
        .asyncMap(decodeMndpRow);
  }
}
