enum WifiDriverFamily { modernWifi, legacyWireless }

class WifiBackendCapabilities {
  final WifiDriverFamily family;
  final String label;
  final String interfacePath;
  final String registrationPath;
  final String securityPath;
  final bool supportsModernProfiles;
  final bool supportsProvisioning;
  final bool supportsModernCapsman;

  const WifiBackendCapabilities({
    required this.family,
    required this.label,
    required this.interfacePath,
    required this.registrationPath,
    required this.securityPath,
    required this.supportsModernProfiles,
    required this.supportsProvisioning,
    required this.supportsModernCapsman,
  });

  static const modern = WifiBackendCapabilities(
    family: WifiDriverFamily.modernWifi,
    label: 'WiFi',
    interfacePath: '/interface/wifi',
    registrationPath: '/interface/wifi/registration-table',
    securityPath: '/interface/wifi/security',
    supportsModernProfiles: true,
    supportsProvisioning: true,
    supportsModernCapsman: true,
  );

  static const legacy = WifiBackendCapabilities(
    family: WifiDriverFamily.legacyWireless,
    label: 'Wireless legacy',
    interfacePath: '/interface/wireless',
    registrationPath: '/interface/wireless/registration-table',
    securityPath: '/interface/wireless/security-profiles',
    supportsModernProfiles: false,
    supportsProvisioning: false,
    supportsModernCapsman: false,
  );

  static WifiBackendCapabilities fromBackendLabel(String? value) {
    final text = (value ?? '').toLowerCase();
    return text.contains('wireless') ? legacy : modern;
  }
}
