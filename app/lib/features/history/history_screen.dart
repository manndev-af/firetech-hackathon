import 'package:flutter/material.dart';

import '../../shared/widgets/personal_page.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _type = 'Semua';
  DateTime? _date;

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'Pilih tanggal riwayat',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (selected != null && mounted) setState(() => _date = selected);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _type != 'Semua' || _date != null;
    return PersonalPage(
      title: 'Riwayat pemindaian',
      subtitle: 'Lihat kembali makanan dan analisis yang kamu simpan.',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in ['Semua', 'Tanpa kemasan', 'Kemasan'])
              ChoiceChip(
                label: Text(type),
                selected: _type == type,
                selectedColor: PersonalColors.chip,
                onSelected: (_) => setState(() => _type = type),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(
                _date == null
                    ? 'Semua tanggal'
                    : '${_date!.day}/${_date!.month}/${_date!.year}',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: PersonalColors.primary,
              ),
            ),
            if (filtered)
              TextButton(
                onPressed: () => setState(() {
                  _type = 'Semua';
                  _date = null;
                }),
                child: const Text('Reset filter'),
              ),
          ],
        ),
        const SizedBox(height: 24),
        PersonalCard(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                width: 112,
                height: 112,
                decoration: const BoxDecoration(
                  color: PersonalColors.soft,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: PersonalColors.chip,
                    child: Icon(
                      Icons.history_rounded,
                      size: 36,
                      color: PersonalColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                filtered
                    ? 'Belum ada hasil yang sesuai'
                    : 'Belum ada hasil tersimpan',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: PersonalColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                filtered
                    ? 'Coba ubah tanggal atau jenis makanan untuk melihat hasil lainnya.'
                    : 'Setelah kamu memindai dan menyimpan analisis makanan, hasilnya akan muncul di sini.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: PersonalColors.secondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kamera makanan belum tersedia.'),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: PersonalColors.primary,
                  minimumSize: const Size(180, 52),
                ),
                icon: const Icon(Icons.camera_alt_outlined, size: 20),
                label: const Text('Mulai pindai'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Riwayat berisi hasil yang disimpan, bukan seluruh konsumsi harianmu.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: PersonalColors.secondary,
            height: 1.5,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
