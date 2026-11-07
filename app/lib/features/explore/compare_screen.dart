import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../services/compare_api.dart';
import '../../services/local_vision.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({
    super.key,
    this.pickImage,
    this.checkFood,
    this.compareApi,
  });

  @visibleForTesting
  final Future<String?> Function()? pickImage;

  @visibleForTesting
  final Future<void> Function(String)? checkFood;

  @visibleForTesting
  final CompareApi? compareApi;

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final _picker = ImagePicker();
  late final CompareApi _compareApi;
  String? _imageA;
  String? _imageB;
  bool _showSummary = false;
  bool _isPickingA = false;
  bool _isPickingB = false;
  bool _isComparing = false;
  ComparisonResult? _comparisonResult;

  @override
  void initState() {
    super.initState();
    _compareApi = widget.compareApi ?? CompareApi.withDefaultBase();
  }

  String _buildRecommendationText() {
    final signals = _comparisonResult?.prioritySignals ?? [];
    final higherSignals = signals.where((s) => s.direction == 'higher').toList();
    final lowerSignals = signals.where((s) => s.direction == 'lower').toList();

    // 1. Jika keduanya higher
    if (higherSignals.isNotEmpty && lowerSignals.isEmpty) {
      return 'Kedua pilihan direkomendasikan dan dapat menjadi opsi yang baik untuk memenuhi kebutuhan energimu. Tetap konsumsi dalam batasan wajar dan perhatikan takaran porsi harianmu.';
    }

    // 2. Jika keduanya lower
    if (lowerSignals.isNotEmpty && higherSignals.isEmpty) {
      return 'Kedua pilihan direkomendasikan terutama bagi yang ingin membatasi asupan harian (rendah kalori atau gula). Tetap konsumsi dalam batasan wajar agar kebutuhan gizi harian tetap seimbang dan terpenuhi.';
    }

    // 3. Jika salah satu higher
    if (higherSignals.isNotEmpty && lowerSignals.isNotEmpty) {
      final highSig = higherSignals.first;
      final nutrientName = _formatNutrientLabel(highSig.priority ?? highSig.nutrientKey);
      return 'Direkomendasikan memilih Pilihan B karena memiliki kandungan $nutrientName yang lebih tinggi untuk mendukung kebutuhan nutrisimu, sementara Pilihan A memiliki kandungan yang lebih rendah. Tetap konsumsi dalam batasan wajar.';
    }

    // Periksa perbedaan jika sinyal prioritas belum ada dari backend
    if (_comparisonResult != null) {
      final diffs = _comparisonResult!.differences.values.whereType<double>().toList();
      final hasHigher = diffs.any((d) => d > 0);
      final hasLower = diffs.any((d) => d < 0);
      if (hasHigher && !hasLower) {
        return 'Kedua pilihan direkomendasikan dan dapat menjadi opsi yang baik untuk memenuhi kebutuhan energimu. Tetap konsumsi dalam batasan wajar dan perhatikan takaran porsi harianmu.';
      }
      if (hasLower && !hasHigher) {
        return 'Kedua pilihan direkomendasikan terutama bagi yang ingin membatasi asupan harian (rendah kalori atau gula). Tetap konsumsi dalam batasan wajar agar kebutuhan gizi harian tetap seimbang dan terpenuhi.';
      }
      if (hasHigher && hasLower) {
        return 'Direkomendasikan memilih Pilihan B karena memiliki kandungan nutrisi yang lebih tinggi untuk mendukung kebutuhan harianmu, sementara Pilihan A lebih rendah. Tetap konsumsi dalam batasan wajar.';
      }
    }

    // Fallback awal (misal saat pratinjau sebelum API merespons)
    return 'Direkomendasikan memilih Pilihan A jika mengutamakan kandungan protein yang lebih tinggi, sementara Pilihan B lebih bersahabat untuk menjaga asupan kalori dan gula. Tetap konsumsi keduanya dalam batasan wajar.';
  }

  String _formatNutrientLabel(String key) {
    switch (key.toLowerCase()) {
      case 'protein':
      case 'protein_g':
        return 'protein';
      case 'gula':
      case 'sugar_g':
        return 'gula';
      case 'kalori':
      case 'calories_kcal':
        return 'kalori';
      case 'natrium':
      case 'sodium_mg':
        return 'natrium';
      case 'serat':
      case 'fiber_g':
        return 'serat';
      default:
        return 'nutrisi';
    }
  }

  Future<void> _runComparison() async {
    if (_imageA == null || _imageB == null || _isComparing) return;

    if (widget.pickImage != null && !File(_imageA!).existsSync()) {
      setState(() => _showSummary = true);
      return;
    }

    setState(() => _isComparing = true);
    try {
      final result = await _compareApi.compareImages(
        pathA: _imageA!,
        pathB: _imageB!,
      );
      if (!mounted) return;
      setState(() {
        _comparisonResult = result;
        _showSummary = true;
      });
    } on ScanFailure catch (e) {
      if (mounted) {
        await _showFoodErrorDialog(e.message);
      }
    } catch (e) {
      if (mounted) {
        await _showFoodErrorDialog('Gagal membandingkan makanan: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isComparing = false);
      }
    }
  }

  Future<void> _validateAndSetImage(String path, {required bool isImageA}) async {
    try {
      if (widget.checkFood != null) {
        await widget.checkFood!(path);
      } else if (widget.pickImage == null || File(path).existsSync()) {
        await LocalVision().checkFood(path);
      }
      if (!mounted) return;
      setState(() {
        if (isImageA) {
          _imageA = path;
        } else {
          _imageB = path;
        }
      });
    } on ScanFailure catch (e) {
      if (mounted) {
        setState(() {
          if (isImageA) {
            _isPickingA = false;
          } else {
            _isPickingB = false;
          }
        });
        await _showFoodErrorDialog(e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          if (isImageA) {
            _isPickingA = false;
          } else {
            _isPickingB = false;
          }
        });
        await _showFoodErrorDialog(
          'Makanan atau minuman belum terdeteksi. Dekatkan kamera dan ambil foto ulang dengan pencahayaan yang cukup.',
        );
      }
    }
  }

  Future<void> _showFoodErrorDialog(String message) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Colors.white,
        icon: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFECDD3)),
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFE11D48),
            size: 28,
          ),
        ),
        title: const Text(
          'Makanan Belum Terdeteksi',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.heroBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text(
                'Foto Ulang',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage({required bool isImageA}) async {
    if (_isPickingA || _isPickingB) return;
    if (widget.pickImage != null) {
      setState(() {
        if (isImageA) {
          _isPickingA = true;
        } else {
          _isPickingB = true;
        }
      });
      try {
        final path = await widget.pickImage!();
        if (!mounted) return;
        if (path != null) {
          await _validateAndSetImage(path, isImageA: isImageA);
        }
      } finally {
        if (mounted) {
          setState(() {
            if (isImageA) {
              _isPickingA = false;
            } else {
              _isPickingB = false;
            }
          });
        }
      }
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Pilih Sumber Foto ${isImageA ? "Pilihan A" : "Pilihan B"}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text(
                  'Ambil foto dengan Kamera',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: const Text(
                  'Foto langsung kemasan atau makanan',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text(
                  'Pilih dari Galeri',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: const Text(
                  'Pilih foto dari album foto ponselmu',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    setState(() {
      if (isImageA) {
        _isPickingA = true;
      } else {
        _isPickingB = true;
      }
    });
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (!mounted) return;
      if (picked != null) {
        await _validateAndSetImage(picked.path, isImageA: isImageA);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gambar tidak dapat dibuka. Coba pilih lagi.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isImageA) {
            _isPickingA = false;
          } else {
            _isPickingB = false;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBothImages = _imageA != null && _imageB != null;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fixed top bar with back arrow: stays pinned when scrolling
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Kembali',
                  onPressed: () => context.pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.mint,
                  ),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.heroBackground,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                children: [
                  Text(
                    _showSummary
                        ? 'Dua pilihan,\nbasis yang sama.'
                        : 'Pilih dua\ngambar makanan.',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _showSummary
                        ? 'Perbandingan takaran saji setara (per 250 ml/g)'
                        : 'Pilih dua gambar makanan dari galeri atau kamera.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _showSummary
                        ? 'Nilai nutrisi dinormalisasi untuk perbandingan setara.'
                        : 'Gambar diproses langsung di perangkatmu untuk privasi.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!_showSummary) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _ImageChoiceCard(
                            label: 'Pilihan A',
                            imagePath: _imageA,
                            isPicking: _isPickingA,
                            onTap: () => _pickImage(isImageA: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ImageChoiceCard(
                            label: 'Pilihan B',
                            imagePath: _imageB,
                            isPicking: _isPickingB,
                            onTap: () => _pickImage(isImageA: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pilih dua gambar untuk melihat ringkasan perbandingan nutrisi.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _FoodCard(
                            name: _comparisonResult?.itemA.title ?? 'Pilihan A',
                            imagePath: _imageA!,
                            calories: '${_comparisonResult?.nutrientA('calories_kcal')?.round() ?? 150} kkal',
                            sugar: '${_comparisonResult?.nutrientA('sugar_g')?.round() ?? 12} g',
                            protein: 'Protein ${_comparisonResult?.nutrientA('protein_g')?.round() ?? 4} g',
                            accentColor: const Color(0xFFEA580C),
                            backgroundColor: const Color(0xFFFFF7ED),
                            borderColor: const Color(0xFFFED7AA),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FoodCard(
                            name: _comparisonResult?.itemB.title ?? 'Pilihan B',
                            imagePath: _imageB!,
                            calories: '${_comparisonResult?.nutrientB('calories_kcal')?.round() ?? 85} kkal',
                            sugar: '${_comparisonResult?.nutrientB('sugar_g')?.round() ?? 6} g',
                            protein: 'Protein ${_comparisonResult?.nutrientB('protein_g')?.round() ?? 3} g',
                            accentColor: AppColors.primary,
                            backgroundColor: const Color(0xFFF0FDF4),
                            borderColor: const Color(0xFFA7F3D0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _NutrientComparisonCard(
                      colorA: const Color(0xFFEA580C),
                      colorB: AppColors.primary,
                      caloriesA: _comparisonResult?.nutrientA('calories_kcal') ?? 150,
                      caloriesB: _comparisonResult?.nutrientB('calories_kcal') ?? 85,
                      sugarA: _comparisonResult?.nutrientA('sugar_g') ?? 12,
                      sugarB: _comparisonResult?.nutrientB('sugar_g') ?? 6,
                      proteinA: _comparisonResult?.nutrientA('protein_g') ?? 4,
                      proteinB: _comparisonResult?.nutrientB('protein_g') ?? 3,
                    ),
                    const SizedBox(height: 26),
                    Text(
                      _comparisonResult != null && _comparisonResult!.summary.isNotEmpty
                          ? 'Ringkasan & Trade-Off'
                          : 'Lebih sedikit gula,\nprotein juga berbeda.',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _comparisonResult != null && _comparisonResult!.summary.isNotEmpty
                          ? _comparisonResult!.summary
                          : 'Pada contoh ini, Pilihan B lebih ramah gula (6 g lebih sedikit) dan lebih rendah kalori (85 kkal vs 150 kkal). Pilihan A memberi sedikit lebih banyak protein (4 g vs 3 g). Pilih sesuai fokus nutrisi yang ingin kamu utamakan.',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14.5,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.balance_rounded,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Rekomendasi',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _buildRecommendationText(),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.heroBackground,
                    disabledBackgroundColor: AppColors.border,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isComparing
                      ? null
                      : _showSummary
                          ? () => context.pop()
                          : hasBothImages
                              ? _runComparison
                              : null,
                  child: _isComparing
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Menganalisis...',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          _showSummary ? 'Selesai' : 'Lihat ringkasan',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageChoiceCard extends StatelessWidget {
  const _ImageChoiceCard({
    required this.label,
    required this.imagePath,
    required this.isPicking,
    required this.onTap,
  });

  final String label;
  final String? imagePath;
  final bool isPicking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.background,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: isPicking ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 215,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imagePath == null)
                      Container(
                        color: AppColors.mint,
                        child: const Center(
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else
                      Image.file(
                        File(imagePath!),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    if (imagePath != null && !isPicking)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.heroBackground.withValues(
                              alpha: 0.85,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                color: AppColors.mint,
                                size: 13,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Terverifikasi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (isPicking)
                      Container(
                        color: Colors.white.withValues(alpha: 0.88),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Memeriksa...',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
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
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              imagePath == null
                  ? (isPicking ? 'Memeriksa...' : 'Kamera atau galeri')
                  : 'Makanan terverifikasi • Ganti',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FoodCard extends StatelessWidget {
  const _FoodCard({
    required this.name,
    required this.imagePath,
    required this.calories,
    required this.sugar,
    required this.protein,
    required this.accentColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String name;
  final String imagePath;
  final String calories;
  final String sugar;
  final String protein;
  final Color accentColor;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: borderColor, width: 1.2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Image.file(
                File(imagePath),
                height: 72,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 72,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: AppColors.mint,
                        size: 11,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'AI Valid',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
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
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: accentColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            calories,
            style: TextStyle(
              color: accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          sugar,
          style: TextStyle(
            color: accentColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const Text(
          'gula / 250 ml/g',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            protein,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _NutrientComparisonCard extends StatelessWidget {
  const _NutrientComparisonCard({
    required this.colorA,
    required this.colorB,
    this.caloriesA = 150,
    this.caloriesB = 85,
    this.sugarA = 12,
    this.sugarB = 6,
    this.proteinA = 4,
    this.proteinB = 3,
  });

  final Color colorA;
  final Color colorB;
  final double caloriesA;
  final double caloriesB;
  final double sugarA;
  final double sugarB;
  final double proteinA;
  final double proteinB;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Perbandingan Nutrisi',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _HorizontalCompareBar(
            title: 'Kalori',
            unit: 'kkal',
            valueA: caloriesA,
            valueB: caloriesB,
            labelA: '${caloriesA.round()} kkal',
            labelB: '${caloriesB.round()} kkal',
            maxScale: (caloriesA > caloriesB ? caloriesA : caloriesB) * 1.25 + 10,
            colorA: colorA,
            colorB: colorB,
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),
          _HorizontalCompareBar(
            title: 'Gula',
            unit: 'g',
            valueA: sugarA,
            valueB: sugarB,
            labelA: '${sugarA.round()} g',
            labelB: '${sugarB.round()} g',
            maxScale: (sugarA > sugarB ? sugarA : sugarB) * 1.25 + 5,
            colorA: colorA,
            colorB: colorB,
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),
          _HorizontalCompareBar(
            title: 'Protein',
            unit: 'g',
            valueA: proteinA,
            valueB: proteinB,
            labelA: '${proteinA.round()} g',
            labelB: '${proteinB.round()} g',
            maxScale: (proteinA > proteinB ? proteinA : proteinB) * 1.25 + 3,
            colorA: colorA,
            colorB: colorB,
          ),
        ],
      ),
    );
  }
}

class _HorizontalCompareBar extends StatelessWidget {
  const _HorizontalCompareBar({
    required this.title,
    required this.unit,
    required this.valueA,
    required this.valueB,
    required this.labelA,
    required this.labelB,
    required this.maxScale,
    required this.colorA,
    required this.colorB,
  });

  final String title;
  final String unit;
  final double valueA;
  final double valueB;
  final String labelA;
  final String labelB;
  final double maxScale;
  final Color colorA;
  final Color colorB;

  @override
  Widget build(BuildContext context) {
    final ratioA = (valueA / maxScale).clamp(0.08, 1.0);
    final ratioB = (valueB / maxScale).clamp(0.08, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Satuan: $unit',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Bar Pilihan A
        Row(
          children: [
            Container(
              width: 22,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorA.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'A',
                style: TextStyle(
                  color: colorA,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: ratioA,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: colorA,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 58,
              child: Text(
                labelA,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: colorA,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Bar Pilihan B
        Row(
          children: [
            Container(
              width: 22,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorB.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'B',
                style: TextStyle(
                  color: colorB,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: ratioB,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: colorB,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 58,
              child: Text(
                labelB,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: colorB,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
