import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/nutrition_profile.dart';
import '../models/scan_history_entry.dart';
import '../models/history_preview_data.dart';
import '../models/scan_draft.dart';
import '../services/local_storage.dart';

final profileSession = ValueNotifier<NutritionProfile>(NutritionProfile());
final analysisAudioSession = ValueNotifier<bool>(false);
final historySession = ValueNotifier<List<ScanHistoryEntry>>([]);
final draftSession = ValueNotifier<List<ScanDraft>>([]);
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
      historySession.value = snapshot.history.isEmpty
          ? [sampleHistoryEntry]
          : snapshot.history;
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
  } catch (_) {
    storageIssue.value = 'Data lokal belum dapat dibuka. Perubahan belum disimpan; coba mulai ulang aplikasi.';
  }
}

void _persist() {
  persistLocalState().catchError((Object _) {});
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
  historySession.value = [
    ...previous.where((item) => item.id != entry.id),
    entry,
  ];
  draftSession.value = drafts.where((item) => item.id != entry.id).toList();
  try {
    await persistLocalState();
  } catch (_) {
    historySession.value = previous;
    draftSession.value = drafts;
    rethrow;
  }
}
