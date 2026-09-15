import 'package:router_os_client/router_os_client.dart' as ros_pkg;

/// Adapter around the pub.dev `router_os_client` package.
///
/// RootMikroManager keeps its internal client as its broad compatibility
/// transport, while this adapter is used for tagged/concurrent/streaming
/// operations where the package is particularly useful.
class PackageRouterOsClient {
  ros_pkg.RouterOSClient? _client;

  bool get connected => _client != null;

  Future<void> connect({
    required String host,
    required int port,
    required String username,
    required String password,
    bool verbose = false,
    bool? useTls,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final client = ros_pkg.RouterOSClient(
      address: host,
      user: username,
      password: password,
      useSsl: useTls ?? port == 8729,
      port: port,
      verbose: verbose,
      timeout: timeout,
    );

    final ok = await client.login();
    if (!ok) {
      client.close();
      throw StateError('Connexion RouterOS refusée.');
    }

    _client?.close();
    _client = client;
  }

  Future<List<Map<String, String>>> talk(
    dynamic command, [
    Map<String, String>? params,
    String? tag,
  ]) => _requireClient().talk(command, params, tag);

  Future<ros_pkg.TaggedResponse> talkTagged(
    dynamic command, [
    Map<String, String>? params,
    String? tag,
  ]) => _requireClient().talkTagged(command, params, tag);

  Stream<ros_pkg.TaggedResponse> talkMultiple(
    List<ros_pkg.TaggedCommand> commands,
  ) => _requireClient().talkMultiple(commands);

  Stream<Map<String, String>> streamData(
    dynamic command, [
    Map<String, String>? params,
    String? tag,
  ]) => _requireClient().streamData(command, params, tag);

  Future<void> cancel(String tag) => _requireClient().cancelTagged(tag);

  Future<bool> isAlive() => _requireClient().isAlive();

  void close() {
    _client?.close();
    _client = null;
  }

  ros_pkg.RouterOSClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError('Aucun routeur connecté via router_os_client.');
    }
    return client;
  }
}
