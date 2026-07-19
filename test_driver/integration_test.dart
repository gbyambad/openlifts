import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

/// Driver for the screenshot integration test. The test base64-encodes each
/// captured PNG into `reportData`; here we decode and write them to
/// `docs/screenshots/<name>.png`. Run via `tool/screenshots.sh`.
Future<void> main() async {
  await integrationDriver(
    responseDataCallback: (data) async {
      if (data == null) return;
      for (final entry in data.entries) {
        final file = File('docs/screenshots/${entry.key}.png');
        await file.create(recursive: true);
        await file.writeAsBytes(base64Decode(entry.value as String));
      }
    },
  );
}
