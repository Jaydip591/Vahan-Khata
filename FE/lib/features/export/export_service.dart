import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Hands a finished file to the phone's share sheet (WhatsApp, Drive, mail, ...).
/// Behind an interface so tests can check what would be shared.
abstract class ExportService {
  Future<void> shareBytes({
    required Uint8List bytes,
    required String fileName, // with extension
    required String mimeType,
    required String text,
  });
}

class PlatformExportService implements ExportService {
  @override
  Future<void> shareBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String text,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType, name: fileName)],
        text: text,
        subject: text,
      ),
    );
  }
}

final exportServiceProvider = Provider<ExportService>(
  (ref) => PlatformExportService(),
);
