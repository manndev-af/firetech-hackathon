import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/router/route_paths.dart';

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
    setState(() => _isPicking = true);
    try {
      final path = widget.pickImage != null
          ? await widget.pickImage!()
          : (await _picker.pickImage(
              source: ImageSource.gallery,
              maxWidth: 1600,
              imageQuality: 85,
            ))?.path;
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF3F9F8),
                      ),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF0B6663),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _showSummary
                        ? 'Dua pilihan,\nbasis yang sama.'
                        : 'Pilih dua\ngambar makanan.',
                    style: const TextStyle(
                      color: Color(0xFF142625),
                      fontSize: 29,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _showSummary
                        ? 'Contoh perbandingan · per 250 ml'
                        : 'Pilih gambar pertama dan kedua dari galeri.',
                    style: const TextStyle(
                      color: Color(0xFF5E7170),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _showSummary
                        ? 'Gambar belum dianalisis. Nilai berikut hanya ilustrasi.'
                        : 'Gambar tetap di perangkat; analisis belum terhubung.',
                    style: const TextStyle(
                      color: Color(0xFF5E7170),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 28),
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
                    const SizedBox(height: 14),
                    const Text(
                      'Pilih dua gambar untuk melihat ringkasan perbandingan.',
                      style: TextStyle(
                        color: Color(0xFF5E7170),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ] else ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => setState(() => _showSummary = false),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Ubah gambar'),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _FoodCard(
                            name: 'Pilihan A',
                            imagePath: _imageA!,
                            sugar: '12 g',
                            protein: 'Protein 4 g',
                            color: const Color(0xFFF3F9F8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FoodCard(
                            name: 'Pilihan B',
                            imagePath: _imageB!,
                            sugar: '6 g',
                            protein: 'Protein 3 g',
                            color: const Color(0xFFE6F4F3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 34),
                    const Text(
                      'Lebih sedikit gula,\nprotein juga berbeda.',
                      style: TextStyle(
                        color: Color(0xFF142625),
                        fontSize: 25,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Pada contoh ini, B mengandung 6 g gula lebih sedikit dengan protein 1 g lebih rendah. Pilih sesuai hal yang ingin kamu perhatikan.',
                      style: TextStyle(
                        color: Color(0xFF5E7170),
                        fontSize: 14,
                        height: 1.45,
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
                    backgroundColor: const Color(0xFF0D6E6B),
                    disabledBackgroundColor: const Color(0xFFE4ECEB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: _showSummary
                      ? () => context.push(AppRoutes.assistant, extra: true)
                      : hasBothImages
                      ? () => setState(() => _showSummary = true)
                      : null,
                  child: Text(
                    _showSummary ? 'Bahas pilihan ini' : 'Lihat ringkasan',
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
    color: const Color(0xFFF3F9F8),
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: isPicking ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 211,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE4ECEB)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: imagePath == null
                    ? const Center(
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 38,
                          color: Color(0xFF0B6663),
                        ),
                      )
                    : Image.file(
                        File(imagePath!),
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Color(0xFF5E7170),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF142625),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              imagePath == null ? 'Pilih dari galeri' : 'Ketuk untuk mengganti',
              style: const TextStyle(color: Color(0xFF5E7170), fontSize: 11),
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
    height: 211,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(imagePath),
            height: 64,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox(
              height: 64,
              child: Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Color(0xFF5E7170),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: const TextStyle(
            color: Color(0xFF142625),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          sugar,
          style: const TextStyle(
            color: Color(0xFF0B6663),
            fontSize: 27,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Text(
          'gula / 250 ml · ilustrasi',
          style: TextStyle(color: Color(0xFF5E7170), fontSize: 10),
        ),
        const Spacer(),
        Text(
          protein,
          style: const TextStyle(color: Color(0xFF142625), fontSize: 12),
        ),
      ],
    ),
  );
}
