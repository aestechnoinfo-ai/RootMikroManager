enum WirelessBackend { wifi, legacy }

extension WirelessBackendX on WirelessBackend {
  String get label => this == WirelessBackend.wifi ? 'WiFi' : 'Wireless';
  String get interfacePath =>
      this == WirelessBackend.wifi ? '/interface/wifi' : '/interface/wireless';
  String get registrationPath => this == WirelessBackend.wifi
      ? '/interface/wifi/registration-table'
      : '/interface/wireless/registration-table';
  String get securityPath => this == WirelessBackend.wifi
      ? '/interface/wifi/security'
      : '/interface/wireless/security-profiles';
}
