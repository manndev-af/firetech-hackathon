import 'dart:convert';
import 'dart:io';

import '../models/nutrition_profile.dart';
import '../models/scan_history_entry.dart';
import '../models/scan_draft.dart';

class LocalSnapshot {
  LocalSnapshot({
    required this.profile,
    this.audioEnabled = false,
    this.history = const [],
    this.drafts = const [],
  });
  final NutritionProfile profile;
  final bool audioEnabled;
  final List<ScanHistoryEntry> history;
  final List<ScanDraft> drafts;

  Map<String, dynamic> toJson() => {
    'version': 1,
    'profile': profile.toJson(),
    'audioEnabled': audioEnabled,
    'history': history
        .where((entry) => !entry.isIllustration)
        .map((entry) => entry.toJson())
        .toList(),
    'drafts': drafts.map((draft) => draft.toJson()).toList(),
  };
  factory LocalSnapshot.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported local data version');
    }
    return LocalSnapshot(
      profile: NutritionProfile.fromJson(
        Map<String, dynamic>.from(json['profile'] as Map),
      ),
      audioEnabled: json['audioEnabled'] as bool,
      drafts: (json['drafts'] as List? ?? [])
          .map(
            (item) =>
                ScanDraft.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      history: (json['history'] as List)
          .map(
            (item) => ScanHistoryEntry.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .where((entry) => !entry.isIllustration)
          .toList(),
    );
  }
}

/// Small on-device snapshot store. Serial writes and a previous snapshot protect
/// against interrupted writes. Corrupt data is never silently replaced by empty data.
class LocalStorage {
  LocalStorage(this.directory);
  final Directory directory;
  Future<void> _writes = Future.value();
  bool recoveredBackup = false;
  File get _current => File('${directory.path}/state.json');
  File get _backup => File('${directory.path}/state.backup.json');

  Future<LocalSnapshot?> read() async {
    await directory.create(recursive: true);
    Object? failure;
    for (final file in [_current, _backup]) {
      if (!await file.exists()) continue;
      try {
        final snapshot = LocalSnapshot.fromJson(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>,
        );
        recoveredBackup = file.path == _backup.path;
        return snapshot;
      } catch (error) {
        failure = error;
      }
    }
    if (failure != null) {
      throw const FormatException('Local data could not be read');
    }
    return null;
  }

  Future<void> write(LocalSnapshot snapshot) {
    final encoded = jsonEncode(snapshot.toJson());
    final operation = _writes.then((_) async {
      final temporary = File('${directory.path}/state.pending.json');
      await directory.create(recursive: true);
      await temporary.writeAsString(encoded, flush: true);
      if (await _current.exists()) {
        // Preserve unreadable snapshots for recovery instead of deleting them.
        if (recoveredBackup) {
          await _current.rename(
            '${directory.path}/state.unreadable.${DateTime.now().microsecondsSinceEpoch}.json',
          );
        } else {
          if (await _backup.exists()) await _backup.delete();
          await _current.rename(_backup.path);
        }
      }
      await temporary.rename(_current.path);
      recoveredBackup = false;
    });
    _writes = operation.catchError((Object _) {});
    return operation;
  }
}
