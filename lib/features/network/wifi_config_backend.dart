enum WifiConfigBackend { modern, legacy }

extension WifiConfigBackendX on WifiConfigBackend {
  String get label =>
      this == WifiConfigBackend.modern ? 'WiFi moderne' : 'Wireless legacy';
  String get accessListPath => this == WifiConfigBackend.modern
      ? '/interface/wifi/access-list'
      : '/interface/wireless/access-list';
}
