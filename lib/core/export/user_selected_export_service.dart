import 'dart:io';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Saves user-facing exports through Android's system document picker.
///
/// Android returns a content URI because the user owns the selected location.
/// Other supported platforms retain a documents-directory fallback.
class UserSelectedExportService {
  const UserSelectedExportService();

  static const _channel = MethodChannel('root_mikro_manager/export');

  Future<String?> saveText({
    required String suggestedName,
    required String mimeType,
    required String content,
  }) => saveBytes(
    suggestedName: suggestedName,
    mimeType: mimeType,
    bytes: Uint8List.fromList(utf8.encode(content)),
  );

  Future<String?> saveBytes({
    required String suggestedName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    if (Platform.isAndroid) {
      return _channel.invokeMethod<String>('saveDocument', {
        'suggestedName': suggestedName,
        'mimeType': mimeType,
        'bytes': bytes,
      });
    }
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$suggestedName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
