import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/scan_draft.dart';
import '../../models/scan_history_entry.dart';
import '../../providers/local_app_state.dart';
import '../../services/analysis_api.dart';
import '../../services/journal_api.dart';
import '../../services/local_vision.dart';
import '../../services/scan_pipeline.dart';
import '../../shared/widgets/personal_page.dart';
import 'scanner_screen.dart';
import 'widgets/analysis_content.dart';

class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({
    required this.photo,
    required this.mode,
    this.draft,
    this.userNote,
    this.pipeline,
    this.api,
    this.readText,
    super.key,
  });
  final XFile photo;
  final ScanMode mode;
  final ScanDraft? draft;
  final String? userNote;
  final ScanPipeline? pipeline;
  final AnalysisApi? api;
  final Future<String> Function(String)? readText;
  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  ScanDraft? _draft;
  ScanHistoryEntry? _result;
  String? _error;
  bool _busy = true;
  bool _saved = false;
  bool _saveFailed = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final storage = localStorage;
      if (storage == null) {
        throw const ScanFailure(
          'Penyimpanan lokal belum siap. Mulai ulang aplikasi sebelum memindai.',
        );
      }
      final effectiveNote = widget.userNote ?? _draft?.note;
      if (_draft == null) {
        final pipeline =
            widget.pipeline ??
            ScanPipeline(storage: storage, readText: widget.readText);
        final draft = await pipeline.prepare(
          widget.photo.path,
          label: widget.mode == ScanMode.label,
          priorities: profileSession.value.priorities,
          note: effectiveNote,
        );
        await saveDraft(draft);
        _draft = draft;
      }
      // Navigating away during local processing must not start a backend request.
      if (!mounted) return;
      final apiResult = await (widget.api ?? AnalysisApi()).analyze(_draft!);
      final result =
          (effectiveNote != null &&
                  effectiveNote.isNotEmpty &&
                  apiResult.userNote == null)
              ? apiResult.copyWith(userNote: effectiveNote)
              : apiResult;
      // Retain a completed response even if the user has navigated away.
      try {
        await saveAnalysis(result);
        _saved = true;
      } catch (_) {
        _saveFailed = true;
      }
      if (!mounted) return;
      setState(() {
        _result = result;
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ScanFailure
              ? error.message
              : 'Proses belum berhasil. Periksa penyimpanan dan coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _retrySave() async {
    if (_result == null || _busy) return;
    setState(() => _busy = true);
    try {
      await saveAnalysis(_result!);
      if (mounted) {
        setState(() {
          _saved = true;
          _saveFailed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hasil belum tersimpan. Periksa ruang penyimpanan.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<bool>(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) {
        Navigator.of(context).pop(_saved);
      }
    },
    child: PersonalPage(
      title: _result == null ? 'Analisis makanan' : 'Hasil analisis',
      subtitle: _result == null
          ? 'Periksa foto dan pahami kandungannya.'
          : 'Periksa nama makanan, porsi, dan informasi nutrisinya.',
      onBack: () => Navigator.pop(context, _saved),
      footer: _result == null
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              decoration: BoxDecoration(
                color: PersonalColors.background,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      key: const Key('save-to-history-button'),
                      icon: const Icon(
                        Icons.bookmark_added_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Simpan ke Riwayat',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.heroBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _busy
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final navigator = Navigator.of(context);
                              setState(() => _busy = true);
                              try {
                                await saveAnalysis(_result!);
                                _saved = true;
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${_result!.name} tersimpan ke Riwayat konsumsi.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: AppColors.heroBackground,
                                  ),
                                );
                                navigator.pop(true);
                              } catch (_) {
                                if (mounted) {
                                  setState(() => _saveFailed = true);
                                }
                              } finally {
                                if (mounted) setState(() => _busy = false);
                              }
                            },
                    ),
                  ),
                  if (_saved)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Center(
                        child: Text(
                          'Tersimpan di Riwayat perangkat ini.',
                          style: TextStyle(
                            color: PersonalColors.secondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  if (_saveFailed) ...[
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Hasil belum berhasil disimpan.',
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                    FilledButton(
                      onPressed: _busy ? null : _retrySave,
                      child: const Text('Coba simpan lagi'),
                    ),
                  ],
                ],
              ),
            ),
      children: [
        if (_result != null) ...[
          AnalysisContent(
            entry: _result!,
            autoSpeak: analysisAudioSession.value,
            onQuantityChanged: (qty) async {
              if (_result != null && _result!.id.isNotEmpty) {
                final existingPhoto = _result!.photoPath ?? _draft?.photoPath;
                final existingNote = _result!.userNote ?? _draft?.note;
                final existingPriorities = _result!.prioritySnapshot.isNotEmpty
                    ? _result!.prioritySnapshot
                    : (_draft?.priorities ?? const <String>[]);
                final existingRawOcr = _result!.rawOcrText ?? _draft?.rawOcrText;

                final updated = await JournalApi().updateQuantity(
                  _result!.id,
                  qty,
                  localPhotoPath: existingPhoto,
                  userNote: existingNote,
                  prioritySnapshot: existingPriorities,
                  rawOcrText: existingRawOcr,
                );
                if (updated != null && mounted) {
                  final preserved = (updated.photoPath == null && existingPhoto != null)
                      ? updated.copyWith(photoPath: existingPhoto)
                      : updated;
                  setState(() => _result = preserved);
                  await saveAnalysis(preserved);
                }
              }
            },
          ),
        ] else ...[
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_busy) const Text('Memeriksa foto dan menyiapkan analisis...'),
          if (_error != null) ...[
            Semantics(
              liveRegion: true,
              child: Text(_error!, style: const TextStyle(height: 1.5)),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _run,
              child: const Text('Coba lagi'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Kembali'),
            ),
          ],
        ],
      ],
    ),
  );
}
