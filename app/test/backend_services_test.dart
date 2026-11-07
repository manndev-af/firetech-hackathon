import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens/models/daily_nutrition_summary.dart';
import 'package:nutrilens/models/nutrition_profile.dart';
import 'package:nutrilens/services/journal_api.dart';
import 'package:nutrilens/services/profile_api.dart';

class RealHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProfileApi', () {
    test('getProfile fetches and deserializes active profile and audio settings', () =>
        HttpOverrides.runWithHttpOverrides(() async {
          final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
          addTearDown(() => server.close(force: true));

          server.listen((HttpRequest request) async {
            expect(request.method, 'GET');
            expect(request.uri.path, '/api/v1/profile');

            request.response.statusCode = 200;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({
              'success': true,
              'message': 'Active profile retrieved',
              'data': {
                'id': 'profile-123',
                'name': 'Budi',
                'age': 28,
                'heightCm': 172.0,
                'weightKg': 68.5,
                'preference': 'low_sugar',
                'priorities': ['Gula', 'Protein'],
                'eatingPattern': 'vegetarian',
                'prefersHalal': true,
                'allergyStatus': 'listed',
                'allergies': ['Kacang'],
                'otherAllergies': '',
                'audioAnalysisEnabled': true,
              },
              'timestamp': '2026-11-07T00:00:00.000Z',
            }));
            await request.response.close();
          });

          final api = ProfileApi(baseUrl: 'http://127.0.0.1:${server.port}');
          final result = await api.getProfile();

          expect(result, isNotNull);
          expect(result!.profile.name, 'Budi');
          expect(result.profile.age, 28);
          expect(result.profile.heightCm, 172.0);
          expect(result.profile.weightKg, 68.5);
          expect(result.profile.priorities, ['Gula', 'Protein']);
          expect(result.profile.prefersHalal, isTrue);
          expect(result.profile.allergyStatus, AllergyStatus.listed);
          expect(result.profile.allergies, ['Kacang']);
          expect(result.audioEnabled, isTrue);
          api.close();
        }, RealHttpOverrides()));

    test('patchProfile updates profile delta and audio settings', () =>
        HttpOverrides.runWithHttpOverrides(() async {
          final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
          addTearDown(() => server.close(force: true));

          server.listen((HttpRequest request) async {
            expect(request.method, 'PATCH');
            expect(request.uri.path, '/api/v1/profile');

            final body = jsonDecode(await utf8.decodeStream(request)) as Map;
            expect(body['audioAnalysisEnabled'], isFalse);
            expect(body['name'], 'Siti');

            request.response.statusCode = 200;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({
              'success': true,
              'message': 'Profile updated',
              'data': {
                'id': 'profile-123',
                'name': 'Siti',
                'age': null,
                'heightCm': null,
                'weightKg': null,
                'preference': '',
                'priorities': ['Natrium'],
                'eatingPattern': 'all',
                'prefersHalal': false,
                'allergyStatus': 'noneKnown',
                'allergies': <String>[],
                'otherAllergies': '',
                'audioAnalysisEnabled': false,
              },
              'timestamp': '2026-11-07T00:00:00.000Z',
            }));
            await request.response.close();
          });

          final api = ProfileApi(baseUrl: 'http://127.0.0.1:${server.port}');
          final result = await api.patchProfile({
            'name': 'Siti',
            'audioAnalysisEnabled': false,
          });

          expect(result, isNotNull);
          expect(result!.profile.name, 'Siti');
          expect(result.profile.priorities, ['Natrium']);
          expect(result.audioEnabled, isFalse);
          api.close();
        }, RealHttpOverrides()));
  });

  group('JournalApi', () {
    test('listEntries queries food-entries and maps 8 nutrients', () =>
        HttpOverrides.runWithHttpOverrides(() async {
          final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
          addTearDown(() => server.close(force: true));

          server.listen((HttpRequest request) async {
            expect(request.method, 'GET');
            expect(request.uri.path, '/api/v1/food-entries');
            expect(request.uri.queryParameters['date'], '2026-11-07');
            expect(request.uri.queryParameters['page'], '1');

            request.response.statusCode = 200;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({
              'success': true,
              'message': 'Entries retrieved',
              'data': {
                'entries': [
                  {
                    'id': 'entry-1',
                    'consumedAt': '2026-11-07T12:00:00.000Z',
                    'mode': 'food',
                    'title': 'Nasi Goreng',
                    'description': 'Porsi makan siang',
                    'quantity': 1.0,
                    'baseQuantity': 1.0,
                    'provenance': 'model_estimate',
                    'pros': ['Tinggi protein'],
                    'cons': ['Cukup tinggi natrium'],
                    'ttsSummary': 'Nasi goreng ini cukup tinggi protein.',
                    'ttsSummarySource': 'model',
                    'nutrients': {
                      'calories_kcal': 350.0,
                      'protein_g': 12.0,
                      'total_fat_g': 10.0,
                      'saturated_fat_g': 3.0,
                      'carbohydrates_g': 45.0,
                      'sugar_g': 2.0,
                      'sodium_mg': 480.0,
                      'fiber_g': 2.5,
                    },
                  }
                ],
                'pagination': {
                  'page': 1,
                  'limit': 50,
                  'total': 1,
                  'hasMore': false,
                },
              },
              'timestamp': '2026-11-07T12:00:00.000Z',
            }));
            await request.response.close();
          });

          final api = JournalApi(baseUrl: 'http://127.0.0.1:${server.port}');
          final entries = await api.listEntries(date: '2026-11-07');

          expect(entries, hasLength(1));
          final entry = entries.first;
          expect(entry.id, 'entry-1');
          expect(entry.name, 'Nasi Goreng');
          expect(entry.energyKcal, 350.0);
          expect(entry.proteinG, 12.0);
          expect(entry.totalFatG, 10.0);
          expect(entry.saturatedFatG, 3.0);
          expect(entry.carbohydratesG, 45.0);
          expect(entry.sugarG, 2.0);
          expect(entry.sodiumMg, 480.0);
          expect(entry.fiberG, 2.5);
          expect(entry.pros, ['Tinggi protein']);
          expect(entry.cons, ['Cukup tinggi natrium']);
          expect(entry.provenance, 'model_estimate');
          api.close();
        }, RealHttpOverrides()));

    test('updateQuantity patches quantity and returns recalculated entry', () =>
        HttpOverrides.runWithHttpOverrides(() async {
          final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
          addTearDown(() => server.close(force: true));

          server.listen((HttpRequest request) async {
            expect(request.method, 'PATCH');
            expect(request.uri.path, '/api/v1/food-entries/entry-1/quantity');

            final body = jsonDecode(await utf8.decodeStream(request)) as Map;
            expect(body['quantity'], 2.0);

            request.response.statusCode = 200;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({
              'success': true,
              'message': 'Quantity updated',
              'data': {
                'id': 'entry-1',
                'consumedAt': '2026-11-07T12:00:00.000Z',
                'mode': 'food',
                'title': 'Nasi Goreng',
                'description': 'Porsi makan siang',
                'quantity': 2.0,
                'baseQuantity': 1.0,
                'provenance': 'model_estimate',
                'pros': ['Tinggi protein'],
                'cons': ['Cukup tinggi natrium'],
                'ttsSummary': 'Nasi goreng ini cukup tinggi protein.',
                'ttsSummarySource': 'model',
                'nutrients': {
                  'calories_kcal': 700.0,
                  'protein_g': 24.0,
                  'total_fat_g': 20.0,
                  'saturated_fat_g': 6.0,
                  'carbohydrates_g': 90.0,
                  'sugar_g': 4.0,
                  'sodium_mg': 960.0,
                  'fiber_g': 5.0,
                },
              },
              'timestamp': '2026-11-07T12:00:00.000Z',
            }));
            await request.response.close();
          });

          final api = JournalApi(baseUrl: 'http://127.0.0.1:${server.port}');
          final updated = await api.updateQuantity('entry-1', 2.0, localPhotoPath: '/local/storage/path.jpg');

          expect(updated, isNotNull);
          expect(updated!.quantity, 2.0);
          expect(updated.energyKcal, 700.0);
          expect(updated.proteinG, 24.0);
          expect(updated.photoPath, '/local/storage/path.jpg');
          api.close();
        }, RealHttpOverrides()));

    test('deleteEntry sends DELETE and handles 204 No Content', () =>
        HttpOverrides.runWithHttpOverrides(() async {
          final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
          addTearDown(() => server.close(force: true));

          server.listen((HttpRequest request) async {
            expect(request.method, 'DELETE');
            expect(request.uri.path, '/api/v1/food-entries/entry-del');

            request.response.statusCode = 204;
            await request.response.close();
          });

          final api = JournalApi(baseUrl: 'http://127.0.0.1:${server.port}');
          final deleted = await api.deleteEntry('entry-del');

          expect(deleted, isTrue);
          api.close();
        }, RealHttpOverrides()));

    test('getDailyNutrition queries daily totals and maps to DailyNutritionSummary', () =>
        HttpOverrides.runWithHttpOverrides(() async {
          final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
          addTearDown(() => server.close(force: true));

          server.listen((HttpRequest request) async {
            expect(request.method, 'GET');
            expect(request.uri.path, '/api/v1/nutrition/daily');

            request.response.statusCode = 200;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({
              'success': true,
              'message': 'Daily nutrition retrieved',
              'data': {
                'date': '2026-11-07',
                'timezone': 'Asia/Jakarta',
                'entryCount': 3,
                'recordedIntakeOnly': true,
                'nutrients': {
                  'calories_kcal': {
                    'knownTotal': 1250.0,
                    'knownCount': 3,
                    'missingCount': 0,
                    'complete': true,
                    'provenanceCounts': {'model_estimate': 3},
                  },
                  'protein_g': {
                    'knownTotal': 45.0,
                    'knownCount': 3,
                    'missingCount': 0,
                    'complete': true,
                    'provenanceCounts': {'model_estimate': 3},
                  },
                  'sugar_g': {
                    'knownTotal': 15.0,
                    'knownCount': 2,
                    'missingCount': 1,
                    'complete': false,
                    'provenanceCounts': {'model_estimate': 2},
                  },
                },
              },
              'timestamp': '2026-11-07T12:00:00.000Z',
            }));
            await request.response.close();
          });

          final api = JournalApi(baseUrl: 'http://127.0.0.1:${server.port}');
          final raw = await api.getDailyNutrition();

          expect(raw, isNotNull);
          final summary = DailyNutritionSummary.fromBackend(raw!);
          expect(summary, isNotNull);
          expect(summary!.recordCount, 3);
          expect(summary.energyKcal, 1250.0);
          expect(summary.energyComplete, isTrue);
          expect(summary.proteinG, 45.0);
          expect(summary.proteinComplete, isTrue);
          expect(summary.sugarG, 15.0);
          expect(summary.sugarComplete, isFalse);
          api.close();
        }, RealHttpOverrides()));
  });
}
