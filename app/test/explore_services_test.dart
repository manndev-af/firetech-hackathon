import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens/core/network/api_client.dart';
import 'package:nutrilens/core/utils/api_exception.dart';
import 'package:nutrilens/services/assistant_api.dart';
import 'package:nutrilens/services/compare_api.dart';
import 'package:nutrilens/services/local_vision.dart';

class RealHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CompareApi', () {
    test('compareImages sends multipart request with images and metadata', () =>
        HttpOverrides.runWithHttpOverrides(() async {
          final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
          addTearDown(() => server.close(force: true));

          var receivedMultipart = false;
          server.listen((HttpRequest request) async {
            expect(request.method, 'POST');
            expect(request.uri.path, '/api/v1/comparisons');
            expect(request.headers.contentType?.mimeType, 'multipart/form-data');

            final bodyBytes = await request.fold<List<int>>([], (p, e) => p..addAll(e));
            final bodyText = utf8.decode(bodyBytes, allowMalformed: true);
            expect(bodyText, contains('name="metadata"'));
            expect(bodyText, contains('name="imageA"'));
            expect(bodyText, contains('name="imageB"'));
            receivedMultipart = true;

            request.response.statusCode = 200;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({
              'success': true,
              'message': 'Perbandingan selesai',
              'data': {
                'items': {
                  'a': {
                    'title': 'Susu Cokelat A',
                    'mode': 'food',
                    'quantity': 1,
                    'portion': {
                      'displayLabel': '1 botol (250 ml)',
                      'referenceVolumeMl': 250,
                    },
                    'nutrients': {
                      'calories_kcal': 160.0,
                      'sugar_g': 18.0,
                      'protein_g': 5.0,
                      'total_fat_g': 4.0,
                      'saturated_fat_g': 2.0,
                      'carbohydrates_g': 26.0,
                      'sodium_mg': 80.0,
                      'fiber_g': 1.0,
                    },
                    'pros': ['Kandungan protein cukup'],
                    'cons': ['Gula tinggi'],
                    'provenance': 'model_estimate',
                  },
                  'b': {
                    'title': 'Susu Kedelai B',
                    'mode': 'food',
                    'quantity': 1,
                    'portion': {
                      'displayLabel': '1 kotak (250 ml)',
                      'referenceVolumeMl': 250,
                    },
                    'nutrients': {
                      'calories_kcal': 110.0,
                      'sugar_g': 7.0,
                      'protein_g': 6.0,
                      'total_fat_g': 3.0,
                      'saturated_fat_g': 0.5,
                      'carbohydrates_g': 14.0,
                      'sodium_mg': 65.0,
                      'fiber_g': 2.0,
                    },
                    'pros': ['Rendah gula', 'Protein nabati baik'],
                    'cons': [],
                    'provenance': 'model_estimate',
                  },
                },
                'comparisonBasis': {
                  'requested': 'per_serving',
                  'status': 'common_basis',
                },
                'comparedNutrients': {
                  'a': {
                    'calories_kcal': 160.0,
                    'sugar_g': 18.0,
                    'protein_g': 5.0,
                  },
                  'b': {
                    'calories_kcal': 110.0,
                    'sugar_g': 7.0,
                    'protein_g': 6.0,
                  },
                },
                'differences': {
                  'calories_kcal': -50.0,
                  'sugar_g': -11.0,
                  'protein_g': 1.0,
                },
                'prioritySignals': [
                  {
                    'nutrientKey': 'sugar_g',
                    'direction': 'lower',
                    'preferredDirection': 'lower',
                    'reason': 'Pilihan B 11 g lebih rendah gula',
                  },
                ],
                'summary': 'Pilihan B lebih bersahabat untuk target rendah gula.',
                'ttsSummary': 'Pilihan B memiliki gula lebih rendah 11 gram dibanding Pilihan A.',
                'ttsSummarySource': 'generated',
                'warnings': [],
              },
              'timestamp': '2026-11-08T00:00:00.000Z',
            }));
            await request.response.close();
          });

          final tempDir = Directory.systemTemp.createTempSync('compare_test_');
          addTearDown(() => tempDir.deleteSync(recursive: true));

          final fileA = File('${tempDir.path}/a.jpg')..writeAsBytesSync([1, 2, 3]);
          final fileB = File('${tempDir.path}/b.jpg')..writeAsBytesSync([4, 5, 6]);

          final api = CompareApi(
            client: ApiClient(baseUri: Uri.parse('http://${server.address.host}:${server.port}')),
          );

          final result = await api.compareImages(
            pathA: fileA.path,
            pathB: fileB.path,
          );

          expect(receivedMultipart, isTrue);
          expect(result.itemA.title, 'Susu Cokelat A');
          expect(result.itemB.title, 'Susu Kedelai B');
          expect(result.nutrientA('calories_kcal'), 160.0);
          expect(result.nutrientB('calories_kcal'), 110.0);
          expect(result.difference('calories_kcal'), -50.0);
          expect(result.difference('sugar_g'), -11.0);
          expect(result.prioritySignals.length, 1);
          expect(result.summary, contains('Pilihan B lebih bersahabat'));
        }, RealHttpOverrides()));

    test('compareImages handles 422 RESCAN_REQUIRED with ScanFailure', () =>
        HttpOverrides.runWithHttpOverrides(() async {
          final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
          addTearDown(() => server.close(force: true));

          server.listen((HttpRequest request) async {
            request.response.statusCode = 422;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({
              'success': false,
              'message': 'Pilihan B belum menunjukkan makanan atau basis yang jelas. Foto ulang pilihan tersebut.',
              'data': {'code': 'RESCAN_REQUIRED'},
              'timestamp': '2026-11-08T00:00:00.000Z',
            }));
            await request.response.close();
          });

          final tempDir = Directory.systemTemp.createTempSync('compare_test_');
          addTearDown(() => tempDir.deleteSync(recursive: true));

          final fileA = File('${tempDir.path}/a.jpg')..writeAsBytesSync([1]);
          final fileB = File('${tempDir.path}/b.jpg')..writeAsBytesSync([2]);

          final api = CompareApi(
            client: ApiClient(baseUri: Uri.parse('http://${server.address.host}:${server.port}')),
          );

          expect(
            () => api.compareImages(pathA: fileA.path, pathB: fileB.path),
            throwsA(
              isA<ScanFailure>().having(
                (e) => e.message,
                'message',
                contains('Pilihan B belum menunjukkan makanan'),
              ),
            ),
          );
        }, RealHttpOverrides()));
  });

  group('AssistantApi', () {
    test('sendMessage sends JSON payload and maps reply with sources', () =>
        HttpOverrides.runWithHttpOverrides(() async {
          final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
          addTearDown(() => server.close(force: true));

          var receivedBody = '';
          server.listen((HttpRequest request) async {
            expect(request.method, 'POST');
            expect(request.uri.path, '/api/v1/assistant/messages');
            expect(request.headers.contentType?.mimeType, 'application/json');

            receivedBody = await utf8.decodeStream(request);
            request.response.statusCode = 200;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({
              'success': true,
              'message': 'Jawaban assistant tersedia.',
              'data': {
                'reply': 'Batas aman konsumsi gula harian adalah 50 gram sesuai Kemenkes RI.',
                'sources': [
                  {
                    'id': 'kemenkes-gula',
                    'title': 'Pedoman Gizi Seimbang Kemenkes RI',
                    'url': 'https://kesmas.kemkes.go.id',
                    'version': '2024',
                  },
                ],
                'warnings': ['Informasi umum tidak menggantikan konsultasi medis.'],
                'contextSummary': {
                  'mode': 'general',
                  'snapshotAt': '2026-11-08T05:00:00.000Z',
                  'timezone': 'Asia/Jakarta',
                  'historyMessageCount': 0,
                  'referencesAvailable': true,
                  'patternEvidence': null,
                },
                'model': 'deepseek-chat',
                'promptVersion': 'assistant-2026-11-v1',
              },
              'timestamp': '2026-11-08T05:00:00.000Z',
            }));
            await request.response.close();
          });

          final api = AssistantApi(
            client: ApiClient(baseUri: Uri.parse('http://${server.address.host}:${server.port}')),
          );

          final response = await api.sendMessage(
            message: 'Berapa batas konsumsi gula?',
            mode: 'general',
          );

          final decoded = jsonDecode(receivedBody) as Map<String, dynamic>;
          expect(decoded['mode'], 'general');
          expect(decoded['message'], 'Berapa batas konsumsi gula?');
          expect(decoded['history'], isEmpty);

          expect(response.reply, contains('50 gram'));
          expect(response.sources.length, 1);
          expect(response.sources.first.title, contains('Pedoman Gizi'));
          expect(response.warnings.length, 1);
          expect(response.mode, 'general');
        }, RealHttpOverrides()));

    test('sendMessage handles pattern mode and maps pattern evidence', () =>
        HttpOverrides.runWithHttpOverrides(() async {
          final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
          addTearDown(() => server.close(force: true));

          server.listen((HttpRequest request) async {
            request.response.statusCode = 200;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({
              'success': true,
              'message': 'Jawaban assistant tersedia.',
              'data': {
                'reply': 'Selama 7 hari terakhir, kamu mencatat 3 kali konsumsi.',
                'sources': [],
                'warnings': [],
                'contextSummary': {
                  'mode': 'pattern',
                  'snapshotAt': '2026-11-08T05:00:00.000Z',
                  'timezone': 'Asia/Jakarta',
                  'historyMessageCount': 0,
                  'referencesAvailable': false,
                  'patternEvidence': {
                    'entryCount': 3,
                    'daysWithEntries': 2,
                    'periodSummary': {
                      'entryCount': 3,
                    },
                  },
                },
                'model': 'deepseek-chat',
                'promptVersion': 'assistant-2026-11-v1',
              },
              'timestamp': '2026-11-08T05:00:00.000Z',
            }));
            await request.response.close();
          });

          final api = AssistantApi(
            client: ApiClient(baseUri: Uri.parse('http://${server.address.host}:${server.port}')),
          );

          final response = await api.sendMessage(
            message: 'Bagaimana pola makan saya?',
            mode: 'pattern',
          );

          expect(response.mode, 'pattern');
          expect(response.patternEvidence?['entryCount'], 3);
          expect(response.patternEvidence?['daysWithEntries'], 2);
        }, RealHttpOverrides()));

    test('sendMessage handles 429 SCAN_BUSY gracefully', () =>
        HttpOverrides.runWithHttpOverrides(() async {
          final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
          addTearDown(() => server.close(force: true));

          server.listen((HttpRequest request) async {
            request.response.statusCode = 429;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({
              'success': false,
              'message': 'Layanan sedang sibuk memproses.',
              'data': {'code': 'SCAN_BUSY'},
              'timestamp': '2026-11-08T00:00:00.000Z',
            }));
            await request.response.close();
          });

          final api = AssistantApi(
            client: ApiClient(baseUri: Uri.parse('http://${server.address.host}:${server.port}')),
          );

          expect(
            () => api.sendMessage(message: 'Halo'),
            throwsA(
              isA<ApiException>().having(
                (e) => e.message,
                'message',
                contains('Layanan AI sedang sibuk'),
              ),
            ),
          );
        }, RealHttpOverrides()));
  });
}
