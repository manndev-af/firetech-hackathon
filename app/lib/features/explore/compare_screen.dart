import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key, this.pickImage});

  @visibleForTesting
  final Future<String?> Function()? pickImage;

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final _picker = ImagePicker();
  String? _imageA;
  String? _imageB;
  bool _showSummary = false;
  bool _isPicking = false;

  Future<void> _pickImage({required bool isImageA}) async {
    if (_isPicking) return;
    if (widget.pickImage != null) {
      setState(() => _isPicking = true);
      try {
        final path = await widget.pickImage!();
        if (!mounted) return;
        if (path != null) {
          setState(() {
            if (isImageA) {
              _imageA = path;
            } else {
              _imageB = path;
            }
          });
        }
      } finally {
        if (mounted) setState(() => _isPicking = false);
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

    setState(() => _isPicking = true);
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (!mounted) return;
      if (picked != null) {
        setState(() {
          if (isImageA) {
            _imageA = picked.path;
          } else {
            _imageB = picked.path;
          }
        });
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
      if (mounted) setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBothImages = _imageA != null && _imageB != null;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                children: [
                  Align(
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
                  const SizedBox(height: 14),
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
                            isPicking: _isPicking,
                            onTap: () => _pickImage(isImageA: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ImageChoiceCard(
                            label: 'Pilihan B',
                            imagePath: _imageB,
                            isPicking: _isPicking,
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => setState(() => _showSummary = false),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text(
                          'Ubah gambar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: _FoodCard(
                            name: 'Pilihan A',
                            imagePath: _imageA!,
                            sugar: '12 g',
                            protein: 'Protein 4 g',
                            color: AppColors.background,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FoodCard(
                            name: 'Pilihan B',
                            imagePath: _imageB!,
                            sugar: '6 g',
                            protein: 'Protein 3 g',
                            color: AppColors.mint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Lebih sedikit gula,\nprotein juga berbeda.',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Pada contoh ini, B mengandung 6 g gula lebih sedikit dengan protein 1 g lebih rendah. Pilih sesuai hal yang ingin kamu perhatikan.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.balance_rounded,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Rekomendasi (Mending yang Mana?):',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            '• Pilihan B lebih ramah gula jika kamu membatasi asupan manis harian.\n• Pilihan A memberi sedikit lebih banyak protein, tetapi gulanya dua kali lipat lebih tinggi.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13.5,
                              height: 1.45,
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
                  onPressed: _showSummary
                      ? () => context.pop()
                      : hasBothImages
                      ? () => setState(() => _showSummary = true)
                      : null,
                  child: Text(
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
                child: imagePath == null
                    ? Container(
                        color: AppColors.mint,
                        child: const Center(
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : Image.file(
                        File(imagePath!),
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.textSecondary,
                          ),
                        ),
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
                  ? 'Kamera atau galeri'
                  : 'Ketuk untuk mengganti',
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
    required this.sugar,
    required this.protein,
    required this.color,
  });

  final String name;
  final String imagePath;
  final String sugar;
  final String protein;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 215,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(imagePath),
            height: 68,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox(
              height: 68,
              child: Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          sugar,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Text(
          'gula / 250 ml · ilustrasi',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Text(
          protein,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
