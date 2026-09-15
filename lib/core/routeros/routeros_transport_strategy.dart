enum RouterOsTransport { socketInternal, socketPackage, restHttps }

/// Documents the transport role inside RootMikroManager.
///
/// We do not force one library to do everything:
/// - internal socket: custom ports + existing stable service layer;
/// - router_os_client: tagged concurrency and long-running streams;
/// - http: RouterOS REST and HTTP-based services.
class RouterOsTransportStrategy {
  const RouterOsTransportStrategy();

  RouterOsTransport forSocket({
    required int port,
    bool needsStreaming = false,
    bool needsConcurrentTags = false,
  }) {
    final standardPort = port == 8728 || port == 8729;

    if (standardPort && (needsStreaming || needsConcurrentTags)) {
      return RouterOsTransport.socketPackage;
    }

    return RouterOsTransport.socketInternal;
  }

  RouterOsTransport forRest({
    required bool routerOsV7,
    required bool restEnabled,
    required bool secure,
  }) {
    if (!routerOsV7 || !restEnabled || !secure) {
      return RouterOsTransport.socketInternal;
    }
    return RouterOsTransport.restHttps;
  }
}
