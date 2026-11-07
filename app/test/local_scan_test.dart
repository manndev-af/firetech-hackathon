import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nutrilens/features/history/widgets/history_entry_card.dart';
import 'package:nutrilens/models/history_preview_data.dart';
import 'package:nutrilens/models/nutrition_profile.dart';
import 'package:nutrilens/models/scan_draft.dart';
import 'package:nutrilens/models/scan_history_entry.dart';
import 'package:nutrilens/providers/local_app_state.dart';
import 'package:nutrilens/services/analysis_api.dart';
import 'package:nutrilens/services/local_storage.dart';
import 'package:nutrilens/services/local_vision.dart';
import 'package:nutrilens/services/scan_image.dart';
import 'package:nutrilens/services/scan_pipeline.dart';
import 'package:nutrilens/services/summary_speech.dart';

class RealHttp extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late LocalStorage storage;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('nutrilens-local-test-');
    storage = LocalStorage(directory);
  });
  tearDown(() async {
    // Only this test's dedicated, resolved temporary directory is removed.
    if (directory.parent.absolute.path == Directory.systemTemp.absolute.path &&
        directory.path.contains('nutrilens-local-test-')) {
      await directory.delete(recursive: true);
    }
  });
  ScanDraft draft(String photo) => ScanDraft(
    id: '108ca11c-e9ae-4f66-b671-5689d998ff19',
    photoPath: photo,
    label: true,
    createdAt: DateTime(2026, 11, 7),
    priorities: ['Gula'],
    rawOcrText: '  Energi 100\nGula 5 g\n',
  );
  Map<String, dynamic> response() => {
    'success': true,
    'data': {
      'foodName': 'Produk',
      'portion': '1 sajian',
      'source': 'Label yang diperiksa',
      'referenceBasis': 'Per sajian',
      'summary': 'Penjelasan panjang yang tidak dibacakan seluruhnya.',
      'spokenSummary': 'Perhatikan gula sesuai porsi yang kamu pilih.',
      'nutrients': {
        'energyKcal': 100,
        'proteinG': 0,
        'sugarG': null,
        'sodiumMg': null,
      },
    },
  };

  test('food gate rejects unknown containers and accepts supported food/drink labels', () {
    expect(
      acceptsFoodPhoto([], [
        const VisionLabel('Cup', .99),
        const VisionLabel('Bottle', .99),
      ]),
      isFalse,
    );
    expect(
      acceptsFoodPhoto([], [
        const VisionLabel('Keyboard', .99),
        const VisionLabel('Chair', .95),
      ]),
      isFalse,
    );
    expect(acceptsFoodPhoto([const VisionLabel('Food', .4)], []), isFalse);
    expect(acceptsFoodPhoto([const VisionLabel('Food', .8)], []), isTrue);
    expect(acceptsFoodPhoto([], [const VisionLabel('Coffee', .9)]), isTrue);
    expect(acceptsFoodPhoto([], [const VisionLabel('Tea', .85)]), isTrue);
    expect(acceptsFoodPhoto([], [const VisionLabel('Milk', .8)]), isTrue);
    expect(acceptsFoodPhoto([], [const VisionLabel('Smoothie', .75)]), isTrue);
    expect(acceptsFoodPhoto([], [const VisionLabel('Dish', .9)]), isTrue);
    expect(
      acceptsFoodPhoto([], [const VisionLabel('Juice', double.nan)]),
      isFalse,
    );
  });

  test('containsNutritionKeywords identifies Indonesian and English nutrition facts terms', () {
    expect(containsNutritionKeywords('INFORMASI NILAI GIZI\nTakaran Saji 100g\nEnergi 120 kkal'), isTrue);
    expect(containsNutritionKeywords('Total Fat 5g, Protein 10g, Sodium 200mg'), isTrue);
    expect(containsNutritionKeywords('Karbohidrat total 15g, gula 2g'), isTrue);
    expect(containsNutritionKeywords('Buku Cerita Bergambar Anak'), isFalse);
    expect(containsNutritionKeywords('Sepatu Olahraga Pria Ukuran 42'), isFalse);
    expect(containsNutritionKeywords(''), isFalse);
  });

  test('label mode throws ScanFailure when OCR text lacks nutrition keywords', () async {
    final input = File('${directory.path}/input_non_food.jpg');
    await input.writeAsBytes([1, 2]);
    final pipeline = ScanPipeline(
      storage: storage,
      requireRawOcr: true,
      checkFood: (_) async => throw StateError('Label must bypass food gate'),
      readText: (_) async => 'Toko Buku Gramedia\nNovel Fiksi 2026',
      resize: (_, label) async => Uint8List.fromList([3, 4]),
    );
    await expectLater(
      pipeline.prepare(input.path, label: true, priorities: ['Gula']),
      throwsA(
        isA<ScanFailure>().having(
          (e) => e.message,
          'message',
          contains('Tabel nilai gizi tidak ditemukan'),
        ),
      ),
    );
  });

  test(
    'optional OCR failures still prepare an image for backend vision',
    () async {
      final input = File('${directory.path}/label.jpg');
      await input.writeAsBytes([1, 2]);
      for (final read in <Future<String> Function(String)>[
        (_) async => throw const ScanFailure('OCR unavailable'),
        (_) async => '',
        (_) async => 'Teks tanpa kata kunci nutrisi',
      ]) {
        final pipeline = ScanPipeline(
          storage: storage,
          requireRawOcr: false,
          readText: read,
          checkFood: (_) async => throw StateError('Label skips food gate'),
          resize: (_, label) async => Uint8List.fromList([3, 4]),
        );
        final result = await pipeline.prepare(
          input.path,
          label: true,
          priorities: [],
        );
        expect(result.label, isTrue);
        expect(await File(result.photoPath).readAsBytes(), [3, 4]);
      }
    },
  );

  test(
    'required OCR fails locally and optional OCR keeps size limits',
    () async {
      final input = File('${directory.path}/label.jpg');
      await input.writeAsBytes([1, 2]);
      for (final required in [false, true]) {
        for (final read in <Future<String> Function(String)>[
          if (required) (_) async => throw const ScanFailure('OCR unavailable'),
          if (required) (_) async => '',
          (_) async => 'a' * 20001,
        ]) {
          final pipeline = ScanPipeline(
            storage: storage,
            requireRawOcr: required,
            readText: read,
            resize: (_, _) async =>
                throw StateError('Must stop before resizing'),
          );
          await expectLater(
            pipeline.prepare(input.path, label: true, priorities: []),
            throwsA(isA<ScanFailure>()),
          );
        }
      }
      expect(await Directory('${directory.path}/photos').exists(), isFalse);
    },
  );

  test('rejected food stops before compression or creating a draft', () async {
    final input = File('${directory.path}/input.jpg');
    await input.writeAsBytes([1, 2]);
    var resized = false;
    final pipeline = ScanPipeline(
      storage: storage,
      checkFood: (_) async => throw const ScanFailure('Tidak terdeteksi'),
      readText: (_) async => throw StateError('Food must not run OCR'),
      resize: (_, label) async {
        resized = true;
        return Uint8List(0);
      },
    );
    await expectLater(
      pipeline.prepare(input.path, label: false, priorities: []),
      throwsA(isA<ScanFailure>()),
    );
    expect(resized, isFalse);
    expect(await Directory('${directory.path}/photos').exists(), isFalse);
  });

  test(
    'label bypasses food gate and preserves raw OCR with its compressed photo',
    () async {
      final input = File('${directory.path}/input.jpg');
      await input.writeAsBytes([1, 2]);
      const raw = '  Energi\n100 kkal\n';
      final pipeline = ScanPipeline(
        storage: storage,
        checkFood: (_) async => throw StateError('Label must bypass gate'),
        readText: (_) async => raw,
        resize: (_, label) async {
          expect(label, isTrue);
          return Uint8List.fromList([3, 4]);
        },
      );
      final result = await pipeline.prepare(
        input.path,
        label: true,
        priorities: ['Protein'],
      );
      expect(result.rawOcrText, raw);
      expect(await File(result.photoPath).readAsBytes(), [3, 4]);
      expect(result.photoPath, isNot(input.path));
    },
  );

  test(
    'resizer bounds dimensions and bytes and does not upscale small images',
    () {
      final photo = img.Image(width: 2400, height: 1200);
      final bytes = resizeScanImage((
        Uint8List.fromList(img.encodeJpg(photo)),
        1600,
      ));
      final resized = img.decodeJpg(bytes)!;
      expect(resized.width, 1600);
      expect(resized.height, 800);
      expect(bytes.length, lessThanOrEqualTo(1500000));
      expect(resized.exif.isEmpty, isTrue);
      final small = resizeScanImage((
        Uint8List.fromList(img.encodePng(img.Image(width: 40, height: 80))),
        1600,
      ));
      expect(img.decodeJpg(small)!.height, 80);
      expect(
        () => resizeScanImage((Uint8List.fromList([1, 2]), 1600)),
        throwsA(isA<ScanFailure>()),
      );
    },
  );

  test('local restart retains full profile, audio preference, raw OCR, history and drafts', () async {
    final pending = draft('${directory.path}/photo.jpg');
    final entry = parseAnalysisResponse(response(), pending);
    await storage.write(
      LocalSnapshot(
        profile: NutritionProfile(
          name: 'Naya',
          age: 22,
          heightCm: 165.5,
          priorities: ['Gula'],
          allergyStatus: AllergyStatus.listed,
          allergies: ['Susu'],
        ),
        audioEnabled: true,
        history: [entry],
        drafts: [pending],
      ),
    );
    final loaded = (await LocalStorage(directory).read())!;
    expect(loaded.profile.heightCm, 165.5);
    expect(loaded.profile.allergies, ['Susu']);
    expect(loaded.audioEnabled, isTrue);
    expect(loaded.history.single.sugarG, isNull);
    expect(loaded.history.single.proteinG, 0);
    expect(loaded.history.single.spokenSummary, entry.spokenSummary);
    expect(loaded.drafts.single.rawOcrText, pending.rawOcrText);
  });

  test('serialized writes preserve newest snapshot and corrupted file recovers backup', () async {
    await Future.wait([
      for (final name in ['one', 'two', 'three'])
        storage.write(LocalSnapshot(profile: NutritionProfile(name: name))),
    ]);
    expect((await storage.read())!.profile.name, 'three');
    await File('${directory.path}/state.json').writeAsString('{broken');
    final recovered = LocalStorage(directory);
    expect((await recovered.read())!.profile.name, 'two');
    expect(recovered.recoveredBackup, isTrue);
    await recovered.write(
      LocalSnapshot(profile: NutritionProfile(name: 'recovered')),
    );
    expect((await LocalStorage(directory).read())!.profile.name, 'recovered');
    expect(
      directory.listSync().where((file) => file.path.contains('unreadable')),
      hasLength(1),
    );
  });

  test('corrupt-only storage fails rather than silently resetting; preview is not persisted', () async {
    await File('${directory.path}/state.json').writeAsString('invalid');
    await expectLater(storage.read(), throwsFormatException);
    final fixture = ScanHistoryEntry(
      id: 'sample',
      name: 'sample',
      savedAt: DateTime.now(),
      packaged: false,
      portion: '',
      source: '',
      referenceBasis: '',
      isIllustration: true,
    );
    final json = LocalSnapshot(
      profile: NutritionProfile(),
      history: [fixture],
    ).toJson();
    expect(json['history'], isEmpty);
  });

  test('draft and history entry retain optional user note through json serialization and analysis', () {
    final originalDraft = ScanDraft(
      id: 'note_draft',
      photoPath: 'test.jpg',
      label: false,
      createdAt: DateTime(2026, 11, 7),
      priorities: ['Protein'],
      note: 'Varian cokelat tanpa gula tambahan',
    );
    final restoredDraft = ScanDraft.fromJson(originalDraft.toJson());
    expect(restoredDraft.note, 'Varian cokelat tanpa gula tambahan');

    final parsedEntry = parseAnalysisResponse(response(), originalDraft);
    expect(parsedEntry.userNote, 'Varian cokelat tanpa gula tambahan');

    final jsonEntry = parsedEntry.toJson();
    final restoredEntry = ScanHistoryEntry.fromJson(jsonEntry);
    expect(restoredEntry.userNote, 'Varian cokelat tanpa gula tambahan');

    final copiedEntry = restoredEntry.copyWith(userNote: 'Updated note');
    expect(copiedEntry.userNote, 'Updated note');
  });

  test('response parser preserves unknown values and rejects invalid nutrients and long audio', () {
    final pending = draft('photo');
    expect(parseAnalysisResponse(response(), pending).sugarG, isNull);
    final invalid = response();
    (invalid['data']['nutrients'] as Map)['sugarG'] = -1;
    expect(
      () => parseAnalysisResponse(invalid, pending),
      throwsFormatException,
    );
    final long = response();
    long['data']['spokenSummary'] = 'x' * 321;
    expect(() => parseAnalysisResponse(long, pending), throwsFormatException);
    final absent = response();
    absent['data'].remove('spokenSummary');
    expect(
      parseAnalysisResponse(absent, pending).spokenSummary,
      isNot(absent['data']['summary']),
    );
  });

  test(
    'configured backend receives unchanged OCR plus JPEG and no personal identity',
    () => HttpOverrides.runWithHttpOverrides(() async {
      final photo = File('${directory.path}/photo.jpg');
      await photo.writeAsBytes([1, 2, 3]);
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final handled = server.first.then((request) async {
        expect(request.uri.path, '/api/v1/scans');
        expect(request.headers.value('Idempotency-Key'), '108ca11c-e9ae-4f66-b671-5689d998ff19');
        expect(request.headers.contentType?.mimeType, 'multipart/form-data');
        final rawBody = await utf8.decodeStream(request);
        expect(rawBody, contains('name="mode"'));
        expect(rawBody, contains('label'));
        expect(rawBody, contains('name="rawOcrText"'));
        expect(rawBody, contains('name="image"'));
        expect(rawBody, contains('filename="photo.jpg"'));
        request.response.statusCode = 201;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'success': true,
          'message': 'Scan recorded',
          'data': {
            'id': '108ca11c-e9ae-4f66-b671-5689d998ff19',
            'consumedAt': '2026-11-07T00:00:00.000Z',
            'mode': 'label',
            'title': 'Produk',
            'description': '',
            'rawOcrText': '  Energi 100\nGula 5 g\n',
            'quantity': 1.0,
            'baseQuantity': 1.0,
            'provenance': 'label_extracted_unverified',
            'pros': ['Rendah lemak'],
            'cons': ['Tinggi gula'],
            'ttsSummary': 'Perhatikan gula sesuai porsi yang kamu pilih.',
            'ttsSummarySource': 'model',
            'nutrients': {
              'calories_kcal': 100.0,
              'protein_g': 0.0,
              'total_fat_g': 2.0,
              'saturated_fat_g': 0.5,
              'carbohydrates_g': 20.0,
              'sugar_g': null,
              'sodium_mg': null,
              'fiber_g': 1.0,
            },
            'analysis': {
              'foodName': 'Produk',
              'summary': 'Penjelasan panjang yang tidak dibacakan seluruhnya.',
              'advantages': ['Rendah lemak'],
              'tradeoffs': ['Tinggi gula'],
            },
          },
          'timestamp': '2026-11-07T00:00:00.000Z',
        }));
        await request.response.close();
      });
      final entry = await AnalysisApi(
        baseUrl: 'http://127.0.0.1:${server.port}',
      ).analyze(draft(photo.path));
      await handled;
      expect(entry.name, 'Produk');
      expect(entry.pros, ['Rendah lemak']);
      expect(entry.cons, ['Tinggi gula']);
      expect(entry.energyKcal, 100);
      expect(entry.sugarG, isNull);
      await expectLater(
        AnalysisApi().analyze(draft(photo.path)),
        throwsA(isA<ScanFailure>()),
      );
    }, RealHttp()),
  );

  test('TTS chooses an offline Indonesian voice and speaks only the short conclusion', () async {
    const channel = MethodChannel('flutter_tts');
    final spoken = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getVoices') {
            return [
              {
                'name': 'id-local',
                'locale': 'id-ID',
                'network_required': '0',
                'features': '',
              },
            ];
          }
          if (call.method == 'speak') {
            spoken.add(
              call.arguments is String
                  ? call.arguments as String
                  : (call.arguments as Map)['text'] as String,
            );
          }
          return 1;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final speech = SummarySpeech();
    await speech.speak('test', 'Perhatikan gula sesuai porsi.');
    expect(spoken, ['Perhatikan gula sesuai porsi.']);
    expect(speech.activeId, isNull);
    await speech.stop();
  });

  test(
    'TTS refuses network-only voice and cancels pending playback when stopped',
    () async {
      const channel = MethodChannel('flutter_tts');
      var spoken = 0;
      Completer<List<Map<String, String>>>? pending;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getVoices') {
              return pending == null
                  ? [
                      {
                        'name': 'network',
                        'locale': 'id-ID',
                        'network_required': '1',
                      },
                    ]
                  : await pending.future;
            }
            if (call.method == 'speak') spoken++;
            return 1;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final speech = SummarySpeech();
      await expectLater(
        speech.speak('network', 'Kesimpulan.'),
        throwsStateError,
      );
      pending = Completer();
      final attempt = speech.speak('pending', 'Kesimpulan.');
      await Future<void>.delayed(Duration.zero);
      await speech.stop();
      pending.complete([
        {'name': 'offline', 'locale': 'id-ID', 'network_required': '0'},
      ]);
      await attempt;
      expect(spoken, 0);
    },
  );

  testWidgets('HistoryEntryCard displays audio button and plays spokenSummary via TTS', (tester) async {
    const channel = MethodChannel('flutter_tts');
    final spoken = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getVoices') {
            return [
              {
                'name': 'id-local',
                'locale': 'id-ID',
                'network_required': '0',
                'features': '',
              },
            ];
          }
          if (call.method == 'speak') {
            spoken.add(
              call.arguments is String
                  ? call.arguments as String
                  : (call.arguments as Map)['text'] as String,
            );
          }
          return 1;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    final entry = ScanHistoryEntry(
      id: 'entry_audio_test',
      name: 'Nasi Goreng',
      savedAt: DateTime(2026, 11, 7, 12, 0),
      packaged: false,
      portion: '1 porsi',
      source: 'TKPI',
      referenceBasis: 'Per porsi',
      spokenSummary: 'Porsi seimbang dan perhatikan minyak.',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryEntryCard(entry: entry),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dengarkan'), findsOneWidget);
    await tester.tap(find.text('Dengarkan'));
    await tester.pumpAndSettle();

    expect(spoken, ['Porsi seimbang dan perhatikan minyak.']);
  });

  test('sampleHistoryEntry is seeded when storage is empty and has concise summary', () async {
    final entry = sampleHistoryEntry;
    expect(entry.isIllustration, isFalse);
    expect(entry.spokenSummary.isNotEmpty, isTrue);
    expect(entry.spokenSummary.length, lessThan(150));
    expect(entry.userNote, isNotNull);

    await initializeLocalState(storage: storage);
    expect(historySession.value, isNotEmpty);
    expect(historySession.value.first.id, 'sample_history_yogurt');
    expect(historySession.value.first.spokenSummary, entry.spokenSummary);
  });
}
