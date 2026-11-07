import 'dart:convert';
import 'dart:io';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/utils/api_exception.dart';
import 'local_vision.dart';

class ComparisonItem {
  const ComparisonItem({
    required this.title,
    required this.mode,
    required this.quantity,
    required this.portionLabel,
    required this.nutrients,
    required this.pros,
    required this.cons,
    required this.provenance,
  });

  factory ComparisonItem.fromJson(Map<String, dynamic> json) {
    final portion = json['portion'] as Map<String, dynamic>? ?? {};
    final rawNutrients = json['nutrients'] as Map<String, dynamic>? ?? {};

    double? parseNutrient(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    final nutrientsMap = <String, double?>{
      'calories_kcal': parseNutrient(rawNutrients['calories_kcal']),
      'protein_g': parseNutrient(rawNutrients['protein_g']),
      'total_fat_g': parseNutrient(rawNutrients['total_fat_g']),
      'saturated_fat_g': parseNutrient(rawNutrients['saturated_fat_g']),
      'carbohydrates_g': parseNutrient(rawNutrients['carbohydrates_g']),
      'sugar_g': parseNutrient(rawNutrients['sugar_g']),
      'sodium_mg': parseNutrient(rawNutrients['sodium_mg']),
      'fiber_g': parseNutrient(rawNutrients['fiber_g']),
    };

    return ComparisonItem(
      title: json['title'] as String? ?? 'Pilihan Makanan',
      mode: json['mode'] as String? ?? 'food',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      portionLabel: portion['displayLabel'] as String? ?? '1 porsi',
      nutrients: nutrientsMap,
      pros: (json['pros'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      cons: (json['cons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      provenance: json['provenance'] as String? ?? 'model_estimate',
    );
  }

  final String title;
  final String mode;
  final double quantity;
  final String portionLabel;
  final Map<String, double?> nutrients;
  final List<String> pros;
  final List<String> cons;
  final String provenance;
}

class PrioritySignal {
  const PrioritySignal({
    required this.nutrientKey,
    required this.direction,
    this.preferredDirection,
    this.reason,
  });

  factory PrioritySignal.fromJson(Map<String, dynamic> json) {
    return PrioritySignal(
      nutrientKey: json['nutrientKey'] as String? ?? '',
      direction: json['direction'] as String? ?? '',
      preferredDirection: json['preferredDirection'] as String?,
      reason: json['reason'] as String?,
    );
  }

  final String nutrientKey;
  final String direction;
  final String? preferredDirection;
  final String? reason;
}

class ComparisonResult {
  const ComparisonResult({
    required this.itemA,
    required this.itemB,
    required this.basisRequested,
    required this.basisStatus,
    this.basisReason,
    required this.comparedNutrientsA,
    required this.comparedNutrientsB,
    required this.differences,
    required this.prioritySignals,
    required this.summary,
    required this.ttsSummary,
    required this.ttsSummarySource,
    required this.warnings,
  });

  factory ComparisonResult.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as Map<String, dynamic>? ?? {};
    final itemA = ComparisonItem.fromJson(items['a'] as Map<String, dynamic>? ?? {});
    final itemB = ComparisonItem.fromJson(items['b'] as Map<String, dynamic>? ?? {});

    final comparisonBasis = json['comparisonBasis'] as Map<String, dynamic>? ?? {};
    final basisRequested = comparisonBasis['requested'] as String? ?? 'per_serving';
    final basisStatus = comparisonBasis['status'] as String? ?? 'as_portioned';
    final basisReason = comparisonBasis['reason'] as String?;

    double? parseNum(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    Map<String, double?> parseNutrientMap(Map<String, dynamic>? raw) {
      if (raw == null) return {};
      return raw.map((k, v) => MapEntry(k, parseNum(v)));
    }

    final comparedNutrients = json['comparedNutrients'] as Map<String, dynamic>? ?? {};
    final comparedA = parseNutrientMap(comparedNutrients['a'] as Map<String, dynamic>?);
    final comparedB = parseNutrientMap(comparedNutrients['b'] as Map<String, dynamic>?);
    final differences = parseNutrientMap(json['differences'] as Map<String, dynamic>?);

    final rawSignals = json['prioritySignals'] as List<dynamic>? ?? [];
    final signals = rawSignals
        .whereType<Map<String, dynamic>>()
        .map(PrioritySignal.fromJson)
        .toList();

    return ComparisonResult(
      itemA: itemA,
      itemB: itemB,
      basisRequested: basisRequested,
      basisStatus: basisStatus,
      basisReason: basisReason,
      comparedNutrientsA: comparedA,
      comparedNutrientsB: comparedB,
      differences: differences,
      prioritySignals: signals,
      summary: json['summary'] as String? ?? '',
      ttsSummary: json['ttsSummary'] as String? ?? '',
      ttsSummarySource: json['ttsSummarySource'] as String? ?? 'generated',
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  final ComparisonItem itemA;
  final ComparisonItem itemB;
  final String basisRequested;
  final String basisStatus;
  final String? basisReason;
  final Map<String, double?> comparedNutrientsA;
  final Map<String, double?> comparedNutrientsB;
  final Map<String, double?> differences;
  final List<PrioritySignal> prioritySignals;
  final String summary;
  final String ttsSummary;
  final String ttsSummarySource;
  final List<String> warnings;

  double? nutrientA(String key) => comparedNutrientsA[key] ?? itemA.nutrients[key];
  double? nutrientB(String key) => comparedNutrientsB[key] ?? itemB.nutrients[key];
  double? difference(String key) => differences[key];
}

class CompareApi {
  CompareApi({required this.client});

  factory CompareApi.withDefaultBase({String? baseUrl, HttpClient? httpClient}) {
    final resolvedUrl = resolveDefaultBaseUrl(baseUrl);
    return CompareApi(
      client: ApiClient(
        baseUri: Uri.parse(resolvedUrl),
        httpClient: httpClient,
      ),
    );
  }

  final ApiClient client;

  Future<ComparisonResult> compareImages({
    required String pathA,
    required String pathB,
    String modeA = 'food',
    String modeB = 'food',
    double quantityA = 1.0,
    double quantityB = 1.0,
    String? noteA,
    String? noteB,
    String basis = 'per_serving',
  }) async {
    final fileA = File(pathA);
    final fileB = File(pathB);

    if (!fileA.existsSync() || !fileB.existsSync()) {
      throw const ScanFailure('Foto makanan yang dipilih tidak ditemukan pada penyimpanan perangkat.');
    }

    final bytesA = await fileA.readAsBytes();
    final bytesB = await fileB.readAsBytes();

    if (bytesA.length > 5 * 1024 * 1024 || bytesB.length > 5 * 1024 * 1024) {
      throw const ScanFailure('Ukuran file foto maksimal 5 MB per gambar.');
    }

    final metadata = {
      'a': {
        'mode': modeA,
        'quantity': quantityA,
        if (noteA != null && noteA.trim().isNotEmpty) 'description': noteA.trim(),
      },
      'b': {
        'mode': modeB,
        'quantity': quantityB,
        if (noteB != null && noteB.trim().isNotEmpty) 'description': noteB.trim(),
      },
      'basis': basis,
    };

    final files = [
      MultipartFileItem(
        field: 'imageA',
        filename: 'imageA.jpg',
        bytes: bytesA,
        mimeType: 'image/jpeg',
      ),
      MultipartFileItem(
        field: 'imageB',
        filename: 'imageB.jpg',
        bytes: bytesB,
        mimeType: 'image/jpeg',
      ),
    ];

    try {
      final response = await client.postMultipartFiles(
        ApiEndpoints.comparisons,
        files: files,
        fields: {
          'metadata': jsonEncode(metadata),
        },
      );

      if (response is Map<String, dynamic>) {
        final data = response['data'] as Map<String, dynamic>? ?? response;
        return ComparisonResult.fromJson(data);
      }
      throw const ScanFailure('Format data perbandingan tidak dikenali.');
    } on ApiException catch (e) {
      if (e.code == 'RESCAN_REQUIRED') {
        throw ScanFailure(e.message);
      } else if (e.code == 'SCAN_BUSY' || e.statusCode == 429) {
        throw const ScanFailure('Layanan AI sedang sibuk menganalisis. Coba beberapa saat lagi.');
      } else if (e.statusCode == 413) {
        throw const ScanFailure('Ukuran data foto terlalu besar melebihi batas server.');
      }
      throw ScanFailure(e.message);
    } catch (e) {
      if (e is ScanFailure) rethrow;
      throw ScanFailure('Gagal melakukan perbandingan: $e');
    }
  }
}
