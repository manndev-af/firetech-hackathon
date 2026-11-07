import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens/features/scanner/scan_result_screen.dart';
import 'package:nutrilens/features/scanner/scanner_screen.dart';
import 'package:nutrilens/features/history/widgets/history_entry_card.dart';
import 'package:nutrilens/models/scan_draft.dart';
import 'package:nutrilens/models/scan_history_entry.dart';
import 'package:nutrilens/providers/local_app_state.dart';
import 'package:nutrilens/services/analysis_api.dart';
import 'package:nutrilens/services/local_storage.dart';
import 'package:nutrilens/services/local_vision.dart';
import 'package:nutrilens/services/scan_pipeline.dart';

class MemoryStorage extends LocalStorage {
  MemoryStorage() : super(Directory('unused'));
  LocalSnapshot? snapshot;
  @override
  Future<void> write(LocalSnapshot value) async {
    snapshot = value;
  }
}

class PreparedPipeline extends ScanPipeline {
  PreparedPipeline({this.reject = false}) : super(storage: MemoryStorage());
  final bool reject;
  @override
  Future<ScanDraft> prepare(
    String path, {
    required bool label,
    required List<String> priorities,
  }) async {
    if (reject) {
      throw const ScanFailure('Makanan atau minuman belum terdeteksi.');
    }
    return ScanDraft(
      id: 'scan_test',
      photoPath: path,
      label: label,
      createdAt: DateTime(2026, 11, 7),
      priorities: priorities,
      rawOcrText: label ? '  Gula 5 g\n' : null,
    );
  }
}

class ReadyApi extends AnalysisApi {
  int calls = 0;
  @override
  Future<ScanHistoryEntry> analyze(ScanDraft draft) async {
    calls++;
    return ScanHistoryEntry(
      id: draft.id,
      name: 'Produk teranalisis',
      savedAt: draft.createdAt,
      packaged: draft.label,
      portion: '1 sajian',
      source: 'Label',
      referenceBasis: 'Per sajian',
      proteinG: 0,
      sugarG: null,
      note: 'Uraian lengkap hasil analisis.',
      spokenSummary: 'Perhatikan porsi yang kamu pilih.',
      rawOcrText: draft.rawOcrText,
    );
  }
}

void main() {
  const channel = MethodChannel('flutter_tts');
  final spoken = <String>[];
  late MemoryStorage storage;
  setUp(() {
    storage = MemoryStorage();
    localStorage = storage;
    historySession.value = [];
    draftSession.value = [];
    analysisAudioSession.value = false;
    spoken.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getVoices') {
            return [
              {'name': 'offline', 'locale': 'id-ID', 'network_required': '0'},
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
  });
  tearDown(() {
    localStorage = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  testWidgets('food rejection never reaches backend or creates history', (
    tester,
  ) async {
    final api = ReadyApi();
    await tester.pumpWidget(
      MaterialApp(
        home: ScanResultScreen(
          photo: XFile('photo'),
          mode: ScanMode.food,
          pipeline: PreparedPipeline(reject: true),
          api: api,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(api.calls, 0);
    expect(historySession.value, isEmpty);
    expect(draftSession.value, isEmpty);
    expect(find.text('Makanan atau minuman belum terdeteksi.'), findsOneWidget);
  });
  testWidgets(
    'unconfigured backend retains raw OCR draft and has no fabricated result',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScanResultScreen(
            photo: XFile('photo'),
            mode: ScanMode.label,
            pipeline: PreparedPipeline(),
            api: AnalysisApi(baseUrl: ''),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(storage.snapshot!.drafts.single.rawOcrText, '  Gula 5 g\n');
      expect(historySession.value, isEmpty);
      expect(find.text('Teks label terbaca'), findsOneWidget);
      expect(find.textContaining('Kopi 78'), findsNothing);
      expect(spoken, isEmpty);
    },
  );
  for (final audio in [false, true]) {
    testWidgets(
      'result is saved locally and auto speech follows preference $audio',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        analysisAudioSession.value = audio;
        final api = ReadyApi();
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: ScanResultScreen(
              photo: XFile('photo'),
              mode: ScanMode.label,
              pipeline: PreparedPipeline(),
              api: api,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(api.calls, 1);
        expect(storage.snapshot!.history.single.proteinG, 0);
        expect(storage.snapshot!.history.single.sugarG, isNull);
        expect(
          storage.snapshot!.history.single.spokenSummary,
          'Perhatikan porsi yang kamu pilih.',
        );
        expect(storage.snapshot!.drafts, isEmpty);
        expect(spoken, audio ? ['Perhatikan porsi yang kamu pilih.'] : isEmpty);
        expect(spoken, isNot(contains('Uraian lengkap hasil analisis.')));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'saved history replays its short text locally without an API call',
    (tester) async {
      final entry = ScanHistoryEntry(
        id: 'saved',
        name: 'Makanan tersimpan',
        savedAt: DateTime(2026, 11, 7),
        packaged: false,
        portion: '1 porsi',
        source: 'Referensi',
        referenceBasis: 'Per porsi',
        note: 'Penjelasan lengkap yang tidak dibacakan.',
        spokenSummary: 'Perhatikan porsi makanan ini.',
      );
      final restored = ScanHistoryEntry.fromJson(entry.toJson());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HistoryEntryDetail(entry: restored)),
        ),
      );
      await tester.pumpAndSettle();
      expect(spoken, isEmpty);
      await tester.ensureVisible(find.text('Dengarkan kesimpulan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dengarkan kesimpulan'));
      await tester.pumpAndSettle();
      expect(spoken, ['Perhatikan porsi makanan ini.']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tapping Simpan ke Riwayat button saves and pops with confirmation',
    (tester) async {
      final api = ReadyApi();
      var popped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScanResultScreen(
                          photo: XFile('photo'),
                          mode: ScanMode.label,
                          pipeline: PreparedPipeline(),
                          api: api,
                        ),
                      ),
                    );
                    popped = true;
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('save-to-history-button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('save-to-history-button')));
      await tester.pumpAndSettle();

      expect(popped, isTrue);
      expect(
        find.textContaining('tersimpan ke Riwayat konsumsi.'),
        findsOneWidget,
      );
    },
  );
}
