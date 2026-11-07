import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../core/theme/app_colors.dart';
import 'label_extraction.dart';
import 'scanner_screen.dart';

class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({
    required this.photo,
    required this.mode,
    this.readText,
    super.key,
  });
  final XFile photo;
  final ScanMode mode;
  final Future<String> Function(String path)? readText;

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  final _form = GlobalKey<FormState>();
  final _serving = TextEditingController();
  final _values = {
    for (final field in labelNutrients) field.label: TextEditingController(),
  };
  String _text = '';
  String? _originalServing;
  String? _error;
  String _basis = 'Belum dipastikan';
  bool _loading = false;
  bool _editing = false;
  bool _confirmed = false;
  bool get _label => widget.mode == ScanMode.label;

  @override
  void initState() {
    super.initState();
    if (_label) _read();
  }

  Future<String> _recognize() async {
    if (widget.readText != null) return widget.readText!(widget.photo.path);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      return (await recognizer.processImage(
        InputImage.fromFilePath(widget.photo.path),
      )).text;
    } finally {
      await recognizer.close();
    }
  }

  Future<void> _read() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final text = await _recognize();
      if (!mounted) return;
      final extraction = extractLabel(text);
      setState(() {
        _text = text;
        _originalServing = extraction.servingText;
        _serving.text = extraction.servingText ?? '';
        _basis = 'Belum dipastikan';
        _confirmed = false;
        for (final field in labelNutrients) {
          final value = extraction.nutrients[field.label];
          _values[field.label]!.text = value == null ? '' : _number(value);
        }
      });
    } catch (_) {
      if (mounted)
        setState(
          () => _error = 'Teks belum berhasil dibaca. Coba lagi, ambil foto lebih jelas, atau isi dari label.',
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _number(double value) =>
      (value == value.roundToDouble()
              ? value.toInt().toString()
              : value.toString())
          .replaceAll('.', ',');

  @override
  void dispose() {
    _serving.dispose();
    for (final controller in _values.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _summary {
    if (!_label)
      return 'Foto sudah siap. Pengenalan makanan belum terhubung, jadi jenis makanan, porsi, dan nilai gizinya belum dapat ditentukan.';
    if (_confirmed)
      return 'Oke, label sudah kamu periksa. Baca angkanya sesuai acuan yang dipilih. Data yang kosong tetap belum tersedia; belum ada penilaian terhadap fokus nutrisimu.';
    if (_text.trim().isEmpty)
      return 'Belum ada angka gizi yang bisa dipastikan. Foto daftar komposisi saja belum tentu memuat nilai gizi. Coba foto tabel informasi nilai gizi atau isi dari label.';
    return 'Teks label sudah terbaca. Yuk, cocokkan angka, satuan, dan takaran sajinya dengan foto sebelum memakai hasil ini. Komposisi saja tidak menentukan nilai gizi.';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      title: Text(
        _label ? 'Hasil baca label' : 'Hasil foto makanan',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    color: AppColors.background,
                    height: 220,
                    child: Image.file(
                      File(widget.photo.path),
                      fit: BoxFit.contain,
                      semanticLabel: _label
                          ? 'Foto label produk'
                          : 'Foto makanan',
                      errorBuilder: (_, error, stack) => const Center(
                        child: Text('Foto tidak dapat ditampilkan.'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _label ? 'Detail label produk' : 'Detail makanan',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _label
                      ? (_confirmed
                            ? 'Diperiksa oleh kamu · sesi ini'
                            : 'Hasil OCR · perlu diperiksa')
                      : 'Identifikasi belum tersedia',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Membaca label di perangkat…'),
                      ],
                    ),
                  )
                else ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ringkasan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _summary,
                          style: const TextStyle(fontSize: 14, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _read,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba baca lagi'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (_editing)
                    _editor()
                  else ...[
                    const Text(
                      'Informasi nilai gizi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Acuan: $_basis',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Takaran saji: ${_serving.text.trim().isEmpty ? 'Belum tersedia' : _serving.text.trim()}',
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    for (final field in labelNutrients)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 20,
                          runSpacing: 4,
                          children: [
                            Text(
                              field.label,
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              _values[field.label]!.text.isEmpty
                                  ? 'Belum tersedia'
                                  : '${_values[field.label]!.text} ${field.unit}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_label) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => setState(() {
                          _editing = true;
                          _confirmed = false;
                        }),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.heroBackground,
                          minimumSize: const Size(double.infinity, 52),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(
                          _confirmed ? 'Ubah hasil' : 'Periksa & koreksi',
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  if (_label)
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text(
                        'Teks & komposisi yang terbaca',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SelectableText(
                            _text.trim().isEmpty
                                ? 'Belum ada teks terbaca.'
                                : _text,
                            style: const TextStyle(fontSize: 14, height: 1.6),
                          ),
                        ),
                      ],
                    ),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text(
                      'Tentang data',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _label
                              ? 'Sumber: foto label yang kamu pilih. OCR dapat salah membaca. Angka adalah salinan label yang perlu diperiksa, bukan hasil perhitungan nutrisi. Takaran asli: ${_originalServing ?? 'belum terbaca'}. Foto dan teks tidak dikirim ke server; hasil belum disimpan ke Riwayat.'
                              : 'Sumber: foto yang kamu pilih. Foto saja tidak menentukan porsi atau nilai gizi. Klasifikasi dan sumber nutrisi belum terhubung; hasil belum disimpan ke Riwayat.',
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kembali ke foto'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _editor() => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Cocokkan dengan label',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          'Kosongkan angka yang tidak tercantum. Jangan isi 0 jika belum diketahui.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          key: const Key('label-basis'),
          initialValue: _basis,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Acuan nilai',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final basis in [
              'Belum dipastikan',
              'Per sajian',
              'Per 100 g',
              'Per 100 ml',
            ])
              DropdownMenuItem(value: basis, child: Text(basis)),
          ],
          onChanged: (value) => setState(() => _basis = value!),
          validator: (value) =>
              value == 'Belum dipastikan' ? 'Pilih acuan sesuai label.' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _serving,
          key: const Key('label-serving'),
          maxLength: 120,
          decoration: const InputDecoration(
            labelText: 'Takaran saji asli',
            hintText: 'Salin ukuran dan satuan dari label',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              _basis == 'Per sajian' && (value?.trim().isEmpty ?? true)
              ? 'Isi takaran saji yang tercantum.'
              : null,
        ),
        for (final field in labelNutrients)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextFormField(
              key: Key('label-${field.label}'),
              controller: _values[field.label],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: field.label,
                suffixText: field.unit,
                hintText: 'Belum tersedia',
                border: const OutlineInputBorder(),
                errorMaxLines: 3,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final number = double.tryParse(
                  value.trim().replaceAll(',', '.'),
                );
                return number == null || !number.isFinite || number < 0
                    ? 'Isi angka positif atau 0 yang tercantum di label.'
                    : null;
              },
            ),
          ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            FocusScope.of(context).unfocus();
            for (final controller in _values.values) {
              controller.text = controller.text.trim().isEmpty
                  ? ''
                  : _number(
                      double.parse(controller.text.trim().replaceAll(',', '.')),
                    );
            }
            setState(() {
              _editing = false;
              _confirmed = true;
            });
          },
          child: const Text('Sudah sesuai label'),
        ),
      ],
    ),
  );
}
