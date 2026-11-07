import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../models/scan_draft.dart';
import '../../models/scan_history_entry.dart';
import '../../providers/local_app_state.dart';
import '../../services/analysis_api.dart';
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
    this.pipeline,
    this.api,
    this.readText,
    super.key,
  });
  final XFile photo;
  final ScanMode mode;
  final ScanDraft? draft;
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
      if (_draft == null) {
        final pipeline =
            widget.pipeline ??
            ScanPipeline(storage: storage, readText: widget.readText);
        final draft = await pipeline.prepare(
          widget.photo.path,
          label: widget.mode == ScanMode.label,
          priorities: profileSession.value.priorities,
        );
        await saveDraft(draft);
        _draft = draft;
      }
      // Navigating away during local processing must not start a backend request.
      if (!mounted) return;
      final result = await (widget.api ?? AnalysisApi()).analyze(_draft!);
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
  Widget build(BuildContext context) => PersonalPage(
    title: _result == null ? 'Analisis makanan' : 'Hasil analisis',
    subtitle: _result == null
        ? 'Periksa foto dan pahami kandungannya.'
        : 'Periksa nama makanan, porsi, dan informasi nutrisinya.',
    onBack: () => Navigator.pop(context),
    children: [
      if (_result != null) ...[
        AnalysisContent(entry: _result!, autoSpeak: analysisAudioSession.value),
        const SizedBox(height: 20),
        if (_saved) const Text('Tersimpan di Riwayat perangkat ini.'),
        if (_saveFailed) ...[
          const Text('Hasil tersedia, tetapi belum berhasil disimpan.'),
          FilledButton(
            onPressed: _busy ? null : _retrySave,
            child: const Text('Coba simpan lagi'),
          ),
        ],
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Kembali'),
          ),
        ],
        if (_draft?.rawOcrText != null) ...[
          const SizedBox(height: 24),
          const PersonalHeading('Teks label terbaca'),
          SelectableText(_draft!.rawOcrText!),
        ],
      ],
    ],
  );
}
