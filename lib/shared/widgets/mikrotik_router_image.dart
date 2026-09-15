import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/network/ip_scanner_service.dart';

class MikrotikRouterImage extends StatelessWidget {
  static String normalizeModel(String value) => value
      .toLowerCase()
      .replaceAll('²', '2')
      .replaceAll('³', '3')
      .replaceFirst(RegExp(r'^(?:mikrotik[\s-]*)?routerboard[\s-]*'), '')
      .replaceFirst(RegExp(r'^rb(?=\d)'), '')
      .replaceAll(RegExp(r'[^a-z0-9+]'), '');

  static String bestModel(List<String> models) => models
      .map((m) => m.trim())
      .firstWhere((m) => m.isNotEmpty, orElse: () => '');
  static final Future<Map<String, String>> _localImages =
      AssetManifest.loadFromAssetBundle(rootBundle).then(
        (manifest) => {
          for (final path in manifest.listAssets())
            if (path.startsWith('lib/assets/images-mikrotik/') &&
                RegExp(
                  r'\.(webp|png|jpe?g)$',
                  caseSensitive: false,
                ).hasMatch(path))
              normalizeModel(
                path
                    .split('/')
                    .last
                    .replaceFirst(
                      RegExp(r'\.(webp|png|jpe?g)$', caseSensitive: false),
                      '',
                    )
                    .trim()
                    .toLowerCase()
                    .replaceFirst(RegExp(r'^mikrotik-routerboard-'), ''),
              ): path,
        },
      );
  final String boardName;
  final List<String> alternativeModels;
  final double size;

  const MikrotikRouterImage({
    super.key,
    required this.boardName,
    this.alternativeModels = const [],
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final models = [
      boardName,
      ...alternativeModels,
    ].map((m) => m.trim()).where((m) => m.isNotEmpty).toList();
    final url = models
        .map(IpScannerService.officialHardwareImageUrl)
        .whereType<String>()
        .firstOrNull;
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.router_outlined),
    );
    final remote = url == null
        ? fallback
        : CachedNetworkImage(
            imageUrl: url,
            width: size,
            height: size,
            fit: BoxFit.contain,
            placeholder: (_, _) => fallback,
            errorWidget: (_, _, _) => fallback,
          );
    return FutureBuilder<Map<String, String>>(
      future: _localImages,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return fallback;
        // A later technical model must not hide a matching product name.
        // Search all aliases for this router before falling back to the CDN.
        final path = models
            .map((model) => snapshot.data?[normalizeModel(model)])
            .whereType<String>()
            .firstOrNull;
        if (path == null) return remote;
        return Image.asset(
          path,
          key: ValueKey(path),
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => remote,
        );
      },
    );
  }
}
