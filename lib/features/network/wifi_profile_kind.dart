enum WifiProfileKind { configuration, channel, security, datapath }

extension WifiProfileKindX on WifiProfileKind {
  String get label => switch (this) {
    WifiProfileKind.configuration => 'Configuration',
    WifiProfileKind.channel => 'Channel',
    WifiProfileKind.security => 'Security',
    WifiProfileKind.datapath => 'Datapath',
  };

  String get path => switch (this) {
    WifiProfileKind.configuration => '/interface/wifi/configuration',
    WifiProfileKind.channel => '/interface/wifi/channel',
    WifiProfileKind.security => '/interface/wifi/security',
    WifiProfileKind.datapath => '/interface/wifi/datapath',
  };
}
