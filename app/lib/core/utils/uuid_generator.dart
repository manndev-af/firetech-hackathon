import 'dart:math';

final _uuidRegex = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

/// Memeriksa apakah string merupakan UUID v1-v5 yang valid sesuai spesifikasi RFC 4122.
bool isValidUuid(String? value) {
  if (value == null) return false;
  return _uuidRegex.hasMatch(value);
}

/// Menghasilkan UUID v4 acak kriptografis sesuai spesifikasi RFC 4122.
String generateUuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  // Versi 4 (0100xxxx)
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  // Varian RFC 4122 (10xxxxxx)
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
}
