import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/daily_nutrition_summary.dart';
import '../models/nutrition_profile.dart';
import '../models/scan_history_entry.dart';
import '../models/history_preview_data.dart';
import '../models/scan_draft.dart';
import '../services/journal_api.dart';
import '../services/local_storage.dart';
import '../services/profile_api.dart';

final profileSession = ValueNotifier<NutritionProfile>(NutritionProfile());
final analysisAudioSession = ValueNotifier<bool>(false);
final historySession = ValueNotifier<List<ScanHistoryEntry>>([]);
final draftSession = ValueNotifier<List<ScanDraft>>([]);
final dailySummarySession = ValueNotifier<DailyNutritionSummary?>(null);
final storageIssue = ValueNotifier<String?>(null);
LocalStorage? localStorage;
bool _listening = false;

Future<void> initializeLocalState({LocalStorage? storage}) async {
  try {
    final candidate =
        storage ?? LocalStorage(await getApplicationSupportDirectory());
    final snapshot = await candidate.read();
    if (snapshot != null) {
      profileSession.value = snapshot.profile;
      analysisAudioSession.value = snapshot.audioEnabled;
      final loadedHistory = (snapshot.history.isEmpty
              ? [sampleHistoryEntry]
              : snapshot.history)
          .toList()
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
      historySession.value = loadedHistory;
      draftSession.value = snapshot.drafts;
    } else {
      historySession.value = [sampleHistoryEntry];
    }
    localStorage = candidate;
    if (candidate.recoveredBackup) {
      storageIssue.value = 'Data dipulihkan dari salinan lokal terakhir.';
    }
    if (!_listening) {
      profileSession.addListener(_persist);
      analysisAudioSession.addListener(_persist);
      _listening = true;
    }
    // Sinkronkan profil dari backend bila tersedia secara asinkron
    ProfileApi().getProfile().then((syncResult) {
      if (syncResult != null) {
        if (profileSession.value.priorities.isEmpty && profileSession.value.name.isEmpty) {
          profileSession.value = syncResult.profile;
        }
        analysisAudioSession.value = syncResult.audioEnabled;
      }
    }).catchError((_) {});

    // Sinkronkan riwayat dan ringkasan nutrisi harian dari backend secara asinkron
    syncHistoryFromBackend().then((_) {
      fetchDailyNutritionFromBackend();
    }).catchError((_) {});
  } catch (_) {
    storageIssue.value = 'Data lokal belum dapat dibuka. Perubahan belum disimpan; coba mulai ulang aplikasi.';
  }
}

Future<void> syncHistoryFromBackend({String? date}) async {
  try {
    final entries = await JournalApi().listEntries(date: date);
    if (entries.isNotEmpty) {
      final current = historySession.value;
      final existingMap = {for (final e in current) e.id: e};
      for (final remote in entries) {
        final local = existingMap[remote.id];
        String? photoPath = (local != null && local.photoPath != null && local.photoPath!.isNotEmpty)
            ? local.photoPath
            : null;
        if (photoPath == null && localStorage != null) {
          final diskFile = File('${localStorage!.directory.path}/photos/${remote.id}.jpg');
          if (diskFile.existsSync()) {
            photoPath = diskFile.path;
          }
        }
        final isYogurtSample = remote.id == 'sample_history_yogurt' ||
            remote.id == 'preview-yogurt' ||
            remote.name.toLowerCase().contains('yogurt');
        final photoAsset = local?.photoAsset ??
            remote.photoAsset ??
            (isYogurtSample ? 'assets/images/history_yogurt.jpg' : null);

        existingMap[remote.id] = remote.copyWith(
          photoPath: photoPath,
          photoAsset: photoAsset,
        );
      }
      final merged = existingMap.values.toList()
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
      historySession.value = merged;
      await persistLocalState();
    }
  } catch (_) {}
}

Future<void> fetchDailyNutritionFromBackend({String? date}) async {
  try {
    final data = await JournalApi().getDailyNutrition(date: date);
    if (data != null) {
      final parsed = DailyNutritionSummary.fromBackend(data);
      if (parsed != null) {
        dailySummarySession.value = parsed;
      }
    }
  } catch (_) {}
}

void _persist() {
  persistLocalState().catchError((Object _) {});
  _syncProfileToBackend();
}

void _syncProfileToBackend() {
  try {
    final p = profileSession.value;
    final delta = <String, dynamic>{
      'name': p.name,
      'age': p.age,
      'heightCm': p.heightCm,
      'weightKg': p.weightKg,
      'preference': p.preference,
      'priorities': p.priorities,
      'eatingPattern': p.eatingPattern,
      'prefersHalal': p.prefersHalal,
      'allergyStatus': p.allergyStatus.name,
      'allergies': p.allergies,
      'otherAllergies': p.otherAllergies,
      'audioAnalysisEnabled': analysisAudioSession.value,
    };
    ProfileApi().patchProfile(delta).catchError((_) => null);
  } catch (_) {}
}

Future<void> persistLocalState() async {
  final storage = localStorage;
  if (storage == null) throw StateError('Local storage unavailable');
  try {
    await storage.write(
      LocalSnapshot(
        profile: profileSession.value,
        audioEnabled: analysisAudioSession.value,
        history: historySession.value,
        drafts: draftSession.value,
      ),
    );
    storageIssue.value = null;
  } catch (_) {
    storageIssue.value = 'Perubahan belum tersimpan di perangkat. Periksa ruang penyimpanan lalu coba lagi.';
    rethrow;
  }
}

Future<void> saveDraft(ScanDraft draft) async {
  final previous = draftSession.value;
  draftSession.value = [
    ...previous.where((item) => item.id != draft.id),
    draft,
  ];
  try {
    await persistLocalState();
  } catch (_) {
    draftSession.value = previous;
    rethrow;
  }
}

Future<void> saveAnalysis(ScanHistoryEntry entry) async {
  final previous = historySession.value;
  final drafts = draftSession.value;

  var effectivePhoto = entry.photoPath;
  if (effectivePhoto == null || effectivePhoto.isEmpty) {
    final existing = previous.where((item) => item.id == entry.id).firstOrNull;
    final draft = drafts.where((item) => item.id == entry.id).firstOrNull;
    effectivePhoto = existing?.photoPath ?? draft?.photoPath;
    if (effectivePhoto == null && localStorage != null) {
      final diskFile = File('${localStorage!.directory.path}/photos/${entry.id}.jpg');
      if (diskFile.existsSync()) {
        effectivePhoto = diskFile.path;
      }
    }
  }
  final resolvedEntry = (effectivePhoto != null && effectivePhoto != entry.photoPath)
      ? entry.copyWith(photoPath: effectivePhoto)
      : entry;

  final isYogurtSample = resolvedEntry.id == 'sample_history_yogurt' ||
      resolvedEntry.id == 'preview-yogurt' ||
      resolvedEntry.name.toLowerCase().contains('yogurt');
  final finalEntry = (resolvedEntry.photoAsset == null && isYogurtSample)
      ? resolvedEntry.copyWith(photoAsset: 'assets/images/history_yogurt.jpg')
      : resolvedEntry;

  final updatedHistory = [
    finalEntry,
    ...previous.where((item) => item.id != finalEntry.id),
  ]..sort((a, b) => b.savedAt.compareTo(a.savedAt));

  historySession.value = updatedHistory;
  draftSession.value = drafts.where((item) => item.id != finalEntry.id).toList();
  try {
    await persistLocalState();
    fetchDailyNutritionFromBackend().catchError((_) {});
  } catch (_) {
    historySession.value = previous;
    draftSession.value = drafts;
    rethrow;
  }
}

Future<void> deleteAnalysis(String id) async {
  final previous = historySession.value;
  historySession.value = previous.where((item) => item.id != id).toList();
  try {
    await persistLocalState();
    fetchDailyNutritionFromBackend().catchError((_) {});
  } catch (_) {
    historySession.value = previous;
    rethrow;
  }
}
