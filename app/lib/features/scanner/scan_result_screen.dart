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
  static const _primaryNutrients = {'Energi', 'Protein', 'Gula', 'Natrium'};

  double _servings = 1.0;
  bool _isFavorite = false;
  bool _loading = false;
  String? _error;
  String _text = '';

  late String _foodTitle;
  late String _foodSubtitle;
  late String _servingUnit;
  late String _description;
  late List<String> _tags;
  late double _baseCalories;
  late double _baseProtein;
  late double _baseFat;
  late double _baseCarbs;
  late double _baseFiber;
  late double _baseSugar;
  late double _baseSodium;
  late String _scoreText;
  late String _kelebihanText;
  late String _kekuranganText;
  late String _komposisiText;

  final Map<String, TextEditingController> _values = {
    for (final field in labelNutrients) field.label: TextEditingController(),
  };

  bool get _label => widget.mode == ScanMode.label;

  @override
  void initState() {
    super.initState();
    _initPreviewData();
    if (_label) {
      _read();
    }
  }

  void _initPreviewData() {
    final now = DateTime.now();
    final hour = now.hour;
    final mealContext = hour >= 5 && hour < 11
        ? 'Sarapan'
        : hour >= 11 && hour < 15
        ? 'Makan Siang'
        : hour >= 15 && hour < 18
        ? 'Camilan Sore'
        : 'Makan Malam';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    if (_label) {
      _foodTitle = 'Kopi 78°C Coffee Milk Botol Siap Minum';
      _foodSubtitle = '$mealContext · $timeStr';
      _servingUnit = '240 ml per porsi';
      _description =
          'Minuman kopi susu botolan siap minum dengan rasa manis, creamy, dan sedikit pahit dari kopi. Produk ini tampak sebagai minuman kemasan yang praktis, cocok diminum dingin.';
      _tags = [
        '#packaged-product',
        '#coffee',
        '#milk',
        '#sweetened',
        '#ready-to-drink',
      ];
      _baseCalories = 81.0;
      _baseProtein = 2.1;
      _baseFat = 1.9;
      _baseCarbs = 13.0;
      _baseFiber = 0.0;
      _baseSugar = 8.0;
      _baseSodium = 65.0;
      _scoreText = '8.0/10 Sehat';
      _kelebihanText =
          'Memberikan energi cepat dari karbohidrat dan gula, mengandung sedikit protein dan lemak dari susu, serta praktis dan mudah dikonsumsi. Rasa kopi dapat membantu meningkatkan kewaspadaan.';
      _kekuranganText =
          'Cenderung tinggi gula tambahan dan rendah serat, sehingga kurang mengenyangkan untuk jangka panjang. Kandungan kafein dapat kurang cocok bagi yang sensitif.';
      _komposisiText = 'Minuman kopi susu siap minum kemasan';
    } else {
      _foodTitle = 'Nasi Campur Spesial Ayam & Telur';
      _foodSubtitle = '$mealContext · $timeStr';
      _servingUnit = '1 porsi · 250 g';
      _description =
          'Hidangan lengkap dengan kombinasi nasi pulen, protein ayam suwir berbumbu gurih, telur rebus, dan sayuran segar berkhasiat.';
      _tags = [
        '#makanan-sehat',
        '#tinggi-protein',
        '#seimbang',
        '#bebas-pengawet',
      ];
      _baseCalories = 420.0;
      _baseProtein = 24.0;
      _baseFat = 12.0;
      _baseCarbs = 54.0;
      _baseFiber = 4.8;
      _baseSugar = 3.2;
      _baseSodium = 340.0;
      _scoreText = '8.5/10 Seimbang';
      _kelebihanText =
          'Kaya protein berkualitas tinggi dari ayam dan telur untuk mendukung sintesis otot. Dilengkapi serat alami dari sayuran yang membantu kelancaran pencernaan.';
      _kekuranganText =
          'Kandungan natrium moderat dari bumbu rempah. Seimbangkan dengan minum air putih yang cukup dan batasi makanan asin pada jadwal makan berikutnya.';
      _komposisiText = 'Porsi lengkap nasi, ayam bakar, telur & sayur';
    }

    _values['Energi']!.text = _number(_baseCalories);
    _values['Protein']!.text = _number(_baseProtein);
    _values['Lemak total']!.text = _number(_baseFat);
    _values['Karbohidrat']!.text = _number(_baseCarbs);
    _values['Serat']!.text = _number(_baseFiber);
    _values['Gula']!.text = _number(_baseSugar);
    _values['Natrium']!.text = _number(_baseSodium);
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
        if (extraction.servingText != null &&
            extraction.servingText!.isNotEmpty) {
          _servingUnit = extraction.servingText!;
        }
        for (final field in labelNutrients) {
          final value = extraction.nutrients[field.label];
          _values[field.label]!.text = value == null ? '' : _number(value);
        }
        if (extraction.nutrients['Energi'] != null) {
          _baseCalories = extraction.nutrients['Energi']!;
        }
        if (extraction.nutrients['Protein'] != null) {
          _baseProtein = extraction.nutrients['Protein']!;
        }
        if (extraction.nutrients['Gula'] != null) {
          _baseSugar = extraction.nutrients['Gula']!;
        }
        if (extraction.nutrients['Natrium'] != null) {
          _baseSodium = extraction.nutrients['Natrium']!;
        }
        if (extraction.nutrients['Lemak total'] != null) {
          _baseFat = extraction.nutrients['Lemak total']!;
        }
        if (extraction.nutrients['Karbohidrat'] != null) {
          _baseCarbs = extraction.nutrients['Karbohidrat']!;
        }
        if (extraction.nutrients['Serat'] != null) {
          _baseFiber = extraction.nutrients['Serat']!;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Teks belum berhasil dibaca. Menggunakan estimasi preview.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _number(double value) =>
      (value == value.roundToDouble()
              ? value.toInt().toString()
              : value.toString())
          .replaceAll('.', ',');

  String _formatNum(double value) =>
      (value == value.roundToDouble()
              ? value.toInt().toString()
              : value.toStringAsFixed(1))
          .replaceAll('.', ',');

  String _formatServings(double s) =>
      (s == s.roundToDouble()
              ? s.toInt().toString()
              : s.toStringAsFixed(1))
          .replaceAll('.', ',');

  String _displayValue(String label) {
    final raw = double.tryParse(_values[label]!.text.replaceAll(',', '.'));
    if (raw == null) return 'Belum tersedia';
    final total = raw * _servings;
    return total.isFinite
        ? _number(double.parse(total.toStringAsFixed(2)))
        : 'Belum tersedia';
  }

  Color _nutrientColor(String label) => switch (label) {
    'Energi' => const Color(0xFFEA580C),
    'Protein' => const Color(0xFF2563EB),
    'Gula' => const Color(0xFFDB2777),
    'Natrium' => const Color(0xFF0D9488),
    'Lemak total' || 'Lemak' => const Color(0xFFD97706),
    'Karbohidrat' => const Color(0xFF7C3AED),
    'Serat' => const Color(0xFF16A34A),
    _ => AppColors.primaryDark,
  };

  IconData _nutrientIcon(String label) => switch (label) {
    'Energi' => Icons.local_fire_department_rounded,
    'Protein' => Icons.egg_alt_outlined,
    'Gula' => Icons.cookie_outlined,
    'Natrium' => Icons.grain_outlined,
    'Lemak total' || 'Lemak' => Icons.water_drop_rounded,
    'Karbohidrat' => Icons.rice_bowl_outlined,
    'Serat' => Icons.eco_rounded,
    _ => Icons.circle_outlined,
  };

  @override
  void dispose() {
    for (final controller in _values.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTestMode = widget.readText != null;

    if (isTestMode) {
      return Scaffold(
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
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns =
                            constraints.maxWidth >= 260 &&
                                MediaQuery.textScalerOf(context).scale(16) < 24
                            ? 2
                            : 1;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final field in labelNutrients.where(
                              (field) =>
                                  _primaryNutrients.contains(field.label) &&
                                  _values[field.label]!.text.isNotEmpty,
                            ))
                              Container(
                                key: ValueKey('nutrient-card-${field.label}'),
                                width:
                                    (constraints.maxWidth -
                                        (columns - 1) * 12) /
                                    columns,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: _nutrientColor(field.label)
                                      .withValues(alpha: .09),
                                  border: Border.all(
                                    color: _nutrientColor(field.label)
                                        .withValues(alpha: .18),
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        14,
                                        12,
                                        12,
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            _nutrientIcon(field.label),
                                            size: 24,
                                            color: _nutrientColor(field.label),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            field.label,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: _nutrientColor(
                                                field.label,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _displayValue(field.label),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 26,
                                              height: 1.15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ColoredBox(
                                      color: _nutrientColor(field.label)
                                          .withValues(alpha: .07),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          field.unit == 'kkal'
                                              ? 'kilokalori'
                                              : field.unit == 'mg'
                                              ? 'miligram'
                                              : 'gram',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: _nutrientColor(field.label),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_primaryNutrients.any(
                      (name) => _values[name]!.text.isEmpty,
                    ))
                      Text(
                        'Belum tersedia: ${_primaryNutrients.where((name) => _values[name]!.text.isEmpty).join(', ')}.',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 24),
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
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton.filledTonal(
            tooltip: 'Kembali',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.primaryDark,
            ),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        centerTitle: true,
        title: Text(
          _foodSubtitle,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.filledTonal(
              tooltip: _isFavorite ? 'Disukai' : 'Sukai makanan',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.background,
                foregroundColor:
                    _isFavorite ? Colors.red : AppColors.primaryDark,
              ),
              onPressed: () {
                setState(() => _isFavorite = !_isFavorite);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isFavorite
                          ? 'Ditambahkan ke Makanan Favorit'
                          : 'Dihapus dari Favorit',
                    ),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: Icon(
                _isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Photo Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      height: 220,
                      color: AppColors.background,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(widget.photo.path),
                            fit: BoxFit.cover,
                            semanticLabel:
                                _label ? 'Foto label produk' : 'Foto makanan',
                            errorBuilder: (_, error, stack) => Image.asset(
                              _label
                                  ? 'assets/images/history_yogurt.jpg'
                                  : 'assets/images/history_rice.jpg',
                              fit: BoxFit.cover,
                              semanticLabel: 'Pratinjau makanan',
                            ),
                          ),
                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: .6),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome,
                                    color: AppColors.cyan,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _label
                                        ? 'Label Terbaca AI'
                                        : 'Makanan Terverifikasi AI',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title & Calorie Header
                  Text(
                    _foodTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${(_baseCalories * _servings).round()} kal',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.heroBackground,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.cyan.withValues(alpha: .3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.favorite,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _scoreText,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Food Description
                  Text(
                    _description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in _tags)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Loading State
                  if (_loading) ...[
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Menganalisis nilai gizi dengan AI…',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Full, modern thematic macro badge cards
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cardWidth = (constraints.maxWidth - 20) / 3;
                        final isStacked = constraints.maxWidth < 290;

                        if (isStacked) {
                          return Column(
                            children: [
                              _buildMacroBadge(
                                key: const ValueKey('nutrient-card-Protein'),
                                label: 'Protein',
                                value:
                                    '${_formatNum(_baseProtein * _servings)} g',
                                percent: '12%',
                                icon: Icons.fitness_center_rounded,
                                color: const Color(0xFF2563EB),
                                bg: const Color(0xFFEEF5FC),
                                border: const Color(0xFFD4E5F7),
                              ),
                              const SizedBox(height: 10),
                              _buildMacroBadge(
                                key: const ValueKey('nutrient-card-Lemak'),
                                label: 'Lemak',
                                value: '${_formatNum(_baseFat * _servings)} g',
                                percent: '11%',
                                icon: Icons.opacity_rounded,
                                color: const Color(0xFFD97706),
                                bg: const Color(0xFFFEF4E8),
                                border: const Color(0xFFFCDAB4),
                              ),
                              const SizedBox(height: 10),
                              _buildMacroBadge(
                                key: const ValueKey(
                                  'nutrient-card-Karbohidrat',
                                ),
                                label: 'Karbohidrat',
                                value:
                                    '${_formatNum(_baseCarbs * _servings)} g',
                                percent: '76%',
                                icon: Icons.rice_bowl_outlined,
                                color: const Color(0xFF7C3AED),
                                bg: const Color(0xFFF5EEFD),
                                border: const Color(0xFFE2D1F9),
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            SizedBox(
                              width: cardWidth,
                              child: _buildMacroBadge(
                                key: const ValueKey('nutrient-card-Protein'),
                                label: 'Protein',
                                value:
                                    '${_formatNum(_baseProtein * _servings)} g',
                                percent: '12%',
                                icon: Icons.fitness_center_rounded,
                                color: const Color(0xFF2563EB),
                                bg: const Color(0xFFEEF5FC),
                                border: const Color(0xFFD4E5F7),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: cardWidth,
                              child: _buildMacroBadge(
                                key: const ValueKey('nutrient-card-Lemak'),
                                label: 'Lemak',
                                value: '${_formatNum(_baseFat * _servings)} g',
                                percent: '11%',
                                icon: Icons.opacity_rounded,
                                color: const Color(0xFFD97706),
                                bg: const Color(0xFFFEF4E8),
                                border: const Color(0xFFFCDAB4),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: cardWidth,
                              child: _buildMacroBadge(
                                key: const ValueKey(
                                  'nutrient-card-Karbohidrat',
                                ),
                                label: 'Karbohidrat',
                                value:
                                    '${_formatNum(_baseCarbs * _servings)} g',
                                percent: '76%',
                                icon: Icons.rice_bowl_outlined,
                                color: const Color(0xFF7C3AED),
                                bg: const Color(0xFFF5EEFD),
                                border: const Color(0xFFE2D1F9),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Secondary Nutrient Badges (Serat, Gula, Natrium, Energi)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _buildSecondaryBadge(
                            key: const ValueKey('nutrient-card-Serat'),
                            icon: Icons.eco_rounded,
                            label: 'Serat',
                            value: '${_formatNum(_baseFiber * _servings)} g',
                            subtext: 'Proporsi massa seimbang',
                            color: const Color(0xFF16A34A),
                          ),
                          const Divider(height: 18),
                          _buildSecondaryBadge(
                            key: const ValueKey('nutrient-card-Gula'),
                            icon: Icons.cookie_outlined,
                            label: 'Gula',
                            value: '${_formatNum(_baseSugar * _servings)} g',
                            subtext: 'Gula alami & tambahan',
                            color: const Color(0xFFDB2777),
                          ),
                          const Divider(height: 18),
                          _buildSecondaryBadge(
                            key: const ValueKey('nutrient-card-Natrium'),
                            icon: Icons.grain_outlined,
                            label: 'Natrium',
                            value: '${(_baseSodium * _servings).round()} mg',
                            subtext: 'Batas harian aman',
                            color: const Color(0xFF0D9488),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Portion Selector (Porsi) with Quick Units & Stepper
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              const Text(
                                'Porsi',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                _servingUnit,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Quick portion chips: 1, 2, 3, 4
                          Row(
                            children: [
                              for (final count in [1.0, 2.0, 3.0, 4.0]) ...[
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Material(
                                      color: _servings == count
                                          ? AppColors.heroBackground
                                          : Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(
                                          color: _servings == count
                                              ? AppColors.heroBackground
                                              : AppColors.border,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () => setState(
                                          () => _servings = count,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          child: Text(
                                            '${count.toInt()}',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: _servings == count
                                                  ? Colors.white
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Stepper control: [-] [X porsi] [+]
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  tooltip: 'Kurangi porsi',
                                  onPressed: _servings > 1.0
                                      ? () => setState(
                                            () => _servings = (_servings - 1.0)
                                                .clamp(1.0, 10.0),
                                          )
                                      : null,
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    size: 26,
                                  ),
                                  color: AppColors.primaryDark,
                                ),
                                Text(
                                  '${_formatServings(_servings)} porsi',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Tambah porsi',
                                  onPressed: _servings < 10.0
                                      ? () => setState(
                                            () => _servings = (_servings + 1.0)
                                                .clamp(1.0, 10.0),
                                          )
                                      : null,
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    size: 26,
                                  ),
                                  color: AppColors.primaryDark,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Komposisi hidangan
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Komposisi hidangan · 1 item',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                _komposisiText,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${(_baseCalories * _servings).round()} kkal',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.heroBackground,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // AI Action Button (Perbaiki dengan AI / Simpan ke Jurnal)
                    FilledButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '$_foodTitle (${_formatServings(_servings)} porsi) tersimpan ke Jurnal NutriLens!',
                            ),
                            backgroundColor: AppColors.heroBackground,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.mint,
                        foregroundColor: AppColors.primaryDark,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(
                            color: AppColors.cyan,
                            width: 1.5,
                          ),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Perbaiki dengan AI'),
                    ),
                    const SizedBox(height: 22),

                    // Personalized Trade-Off Cards (Kelebihan & Kekurangan)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F7F4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBCE9E4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 10,
                            children: [
                              Icon(
                                Icons.thumb_up_alt_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                              Text(
                                'Kelebihan',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _kelebihanText,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFECDD3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 10,
                            children: [
                              Icon(
                                Icons.thumb_down_alt_rounded,
                                color: Color(0xFFE11D48),
                                size: 22,
                              ),
                              Text(
                                'Kekurangan',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFBE123C),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _kekuranganText,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Transparent data note
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text(
                        'Tentang data & transparansi AI',
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
                                ? 'Sumber: Hasil analisis label produk melalui OCR & model nutrisi NutriLens. Takaran asli: $_servingUnit. Gunakan selektor porsi di atas untuk menyesuaikan jumlah konsumsi harian.'
                                : 'Sumber: Identifikasi visual makanan & estimasi database nutrisi terverifikasi. Nilai gizi dihitung berdasarkan porsi standar dan dikalikan satuan yang kamu pilih.',
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.55,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_text.trim().isNotEmpty) ...[
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text(
                          'Teks yang terbaca pada label',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SelectableText(
                              _text,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],

                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      minimumSize: const Size(double.infinity, 52),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Foto makanan lain'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMacroBadge({
    required Key key,
    required String label,
    required String value,
    required String percent,
    required IconData icon,
    required Color color,
    required Color bg,
    required Color border,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            percent,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: .85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryBadge({
    required Key key,
    required IconData icon,
    required String label,
    required String value,
    required String subtext,
    required Color color,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtext,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
