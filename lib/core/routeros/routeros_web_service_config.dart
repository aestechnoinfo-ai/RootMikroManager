class RouterOsWebServiceConfig {
  final bool useHttps;
  final int port;
  final bool allowSelfSignedCertificate;

  const RouterOsWebServiceConfig({
    required this.useHttps,
    required this.port,
    this.allowSelfSignedCertificate = false,
  });

  const RouterOsWebServiceConfig.https({
    this.port = 443,
    this.allowSelfSignedCertificate = false,
  }) : useHttps = true;

  const RouterOsWebServiceConfig.http({this.port = 80})
    : useHttps = false,
      allowSelfSignedCertificate = false;

  String get scheme => useHttps ? 'https' : 'http';

  String get label => '${useHttps ? 'HTTPS' : 'HTTP'} : $port';
}
