import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

Future<void> dumpRenderBoundaryToFile(
  RenderRepaintBoundary boundary,
  String fileName,
) async {
  final image = await boundary.toImage(pixelRatio: 1.0);
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      return;
    }
    final directory = Directory(
      '${Directory.current.path}${Platform.pathSeparator}runtime_logs',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final file = File(
      '${directory.path}${Platform.pathSeparator}$fileName.png',
    );
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  } finally {
    image.dispose();
  }
}
