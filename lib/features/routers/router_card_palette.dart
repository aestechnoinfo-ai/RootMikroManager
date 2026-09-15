import 'package:flutter/material.dart';

import '../../data/models/router_model.dart';

class RouterCardPalette {
  const RouterCardPalette._();

  static const _lightColors = <Color>[
    Color(0xFFC8E6C9), // Vert
    Color(0xFFBBDEFB), // Bleu
    Color(0xFFFFCCBC), // Orange
    Color(0xFFF8BBD0), // Rose
    Color(0xFFE1BEE7), // Violet
    Color(0xFFB2DFDB), // Turquoise
    Color(0xFFFFE082), // Ambre
    Color(0xFFC5CAE9), // Indigo
  ];

  static const _darkColors = <Color>[
    Color(0xFF183B20),
    Color(0xFF17354D),
    Color(0xFF49321D),
    Color(0xFF4A2430),
    Color(0xFF3B2948),
    Color(0xFF173D3A),
    Color(0xFF443B19),
    Color(0xFF292F4D),
  ];

  /// Returns a visually varied but stable color for a router.
  ///
  /// A user-defined database color has priority. Otherwise the same router
  /// always receives the same palette entry, including after an app restart.
  static Color colorFor(RouterModel router, Brightness brightness) {
    if (router.colorValue != null) {
      return Color(router.colorValue!).withValues(alpha: 1);
    }

    final identity = router.macAddress.trim().isNotEmpty
        ? router.macAddress.trim().toLowerCase()
        : router.id != null
        ? 'id:${router.id}'
        : '${router.host.trim().toLowerCase()}:${router.port}';
    final colors = brightness == Brightness.dark ? _darkColors : _lightColors;
    return colors[_stableHash(identity) % colors.length];
  }

  static int _stableHash(String value) {
    var hash = 0x811C9DC5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }
    return hash;
  }
}
