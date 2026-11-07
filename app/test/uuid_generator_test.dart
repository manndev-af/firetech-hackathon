import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens/core/utils/uuid_generator.dart';

void main() {
  group('UUID Generator', () {
    test('generateUuidV4 generates RFC 4122 compliant UUID v4 strings', () {
      final backendRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );

      for (var i = 0; i < 100; i++) {
        final uuid = generateUuidV4();
        expect(uuid, hasLength(36));
        expect(isValidUuid(uuid), isTrue);
        expect(backendRegex.hasMatch(uuid), isTrue, reason: 'Failed for $uuid');
        // Version must be 4
        expect(uuid[14], '4');
        // Variant must be 8, 9, a, or b
        expect(['8', '9', 'a', 'b'].contains(uuid[19].toLowerCase()), isTrue);
      }
    });

    test('isValidUuid rejects non-UUID strings', () {
      expect(isValidUuid(null), isFalse);
      expect(isValidUuid(''), isFalse);
      expect(isValidUuid('scan_12345'), isFalse);
      expect(isValidUuid('not-a-uuid'), isFalse);
      expect(isValidUuid('108ca11c-e9ae-4f66-b671-5689d998ff19'), isTrue);
    });
  });
}
