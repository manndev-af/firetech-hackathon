import 'dart:io';

import 'package:flutter/material.dart';

import '../../../models/scan_history_entry.dart';
import '../../../providers/local_app_state.dart';
import '../../../services/summary_speech.dart';
import '../../../shared/widgets/personal_page.dart';

class AnalysisContent extends StatefulWidget {
  const AnalysisContent({
    required this.entry,
    this.autoSpeak = false,
    super.key,
  });
  final ScanHistoryEntry entry;
  final bool autoSpeak;
  @override
  State<AnalysisContent> createState() => _AnalysisContentState();
}

class _AnalysisContentState extends State<AnalysisContent>
    with WidgetsBindingObserver {
  final _speech = SummarySpeech.shared;
  String? _audioError;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    analysisAudioSession.addListener(_preferenceChanged);
    if (widget.autoSpeak) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && analysisAudioSession.value) _speak();
      });
    }
  }

  void _preferenceChanged() {
    if (!analysisAudioSession.value && _speech.activeId == widget.entry.id) {
      _speech.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _speech.stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    analysisAudioSession.removeListener(_preferenceChanged);
    _speech.stop();
    super.dispose();
  }

  Future<void> _speak() async {
    setState(() => _audioError = null);
    try {
      await _speech.speak(widget.entry.id, widget.entry.spokenSummary);
    } catch (error) {
      if (mounted) {
        setState(
          () => _audioError = error is StateError ? error.message.toString() : 'Suara belum tersedia. Periksa suara Bahasa Indonesia di pengaturan perangkat.',
        );
      }
    }
  }

  String _value(double? value, String unit) => value == null
      ? 'Belum tersedia'
      : '${value == value.roundToDouble() ? value.toInt() : value} $unit';

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (entry.photoPath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.file(
              File(entry.photoPath!),
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stack) => const SizedBox(
                height: 100,
                child: Center(child: Text('Foto tidak tersedia')),
              ),
            ),
          ),
        const SizedBox(height: 20),
        Text(
          entry.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          entry.portion,
          style: const TextStyle(color: PersonalColors.secondary),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: PersonalColors.soft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PersonalHeading('Kesimpulan singkat'),
              Text(
                entry.spokenSummary.isEmpty
                    ? 'Kesimpulan singkat belum tersedia.'
                    : entry.spokenSummary,
                style: const TextStyle(height: 1.5),
              ),
              if (entry.spokenSummary.isNotEmpty)
                ListenableBuilder(
                  listenable: _speech,
                  builder: (context, _) => TextButton.icon(
                    onPressed: () => _speech.activeId == entry.id
                        ? _speech.stop()
                        : _speak(),
                    icon: Icon(
                      _speech.activeId == entry.id
                          ? Icons.stop_circle_outlined
                          : Icons.volume_up_outlined,
                    ),
                    label: Text(
                      _speech.activeId == entry.id
                          ? 'Hentikan suara'
                          : 'Dengarkan kesimpulan',
                    ),
                  ),
                ),
              if (_audioError != null)
                Text(_audioError!, semanticsLabel: _audioError),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const PersonalHeading('Ringkasan analisis'),
        Text(entry.note, style: const TextStyle(height: 1.5)),
        const SizedBox(height: 24),
        const PersonalHeading('Kandungan nutrisi'),
        for (final row in [
          ('Energi', _value(entry.energyKcal, 'kkal')),
          ('Protein', _value(entry.proteinG, 'g')),
          ('Gula', _value(entry.sugarG, 'g')),
          ('Natrium', _value(entry.sodiumMg, 'mg')),
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              children: [
                Text(row.$1),
                Text(
                  row.$2,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Tentang data nutrisi'),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(entry.source),
              subtitle: Text(entry.referenceBasis),
            ),
            if (entry.rawOcrText != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SelectableText(entry.rawOcrText!),
              ),
          ],
        ),
      ],
    );
  }
}
