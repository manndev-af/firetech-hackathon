import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'local_vision.dart';

Uint8List resizeScanImage((Uint8List, int) input) {
  final decoder = img.findDecoderForData(input.$1);
  final info = decoder?.startDecode(input.$1);
  if (info == null || info.width * info.height > 40000000) {
    throw const ScanFailure(
      'Foto tidak didukung atau resolusinya terlalu besar.',
    );
  }
  final decoded = decoder!.decodeFrame(0);
  if (decoded == null) throw const ScanFailure('File foto tidak dapat dibaca.');
  var image = img.bakeOrientation(decoded);
  if (image.width > input.$2 || image.height > input.$2) {
    image = img.copyResize(
      image,
      width: image.width >= image.height ? input.$2 : null,
      height: image.height > image.width ? input.$2 : null,
    );
  }
  // Copy pixels to a fresh image to drop EXIF/GPS and ancillary metadata.
  image = img.Image.fromBytes(
    width: image.width,
    height: image.height,
    bytes: image.getBytes(order: img.ChannelOrder.rgb).buffer,
    numChannels: 3,
  );
  for (final quality in [85, 75, 65]) {
    final bytes = img.encodeJpg(image, quality: quality);
    if (bytes.length <= 1500000) return bytes;
  }
  throw const ScanFailure(
    'Foto masih terlalu besar untuk dikirim. Coba foto ulang lebih dekat.',
  );
}

Future<Uint8List> prepareScanImage(String path, {required bool label}) async {
  final file = File(path);
  if (await file.length() > 20000000) {
    throw const ScanFailure('Ukuran foto maksimal 20 MB.');
  }
  return compute(resizeScanImage, (
    await file.readAsBytes(),
    label ? 2000 : 1600,
  ));
}
