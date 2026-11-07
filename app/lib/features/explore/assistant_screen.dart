import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key, this.showConversation = false});
  final bool showConversation;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
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
                const SizedBox(height: 4),
                const Text(
                  'Asisten nutrisi',
                  style: TextStyle(
                    color: Color(0xFF142625),
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  showConversation
                      ? 'Fokus gula · pola dari catatanmu'
                      : 'Pilih makanan yang ingin kamu pahami',
                  style: const TextStyle(
                    color: Color(0xFF0B6663),
                    fontSize: 12,
                  ),
                ),
                if (showConversation) ...[
                  const SizedBox(height: 28),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 298),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D6E6B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Lihat pola makanan yang sering aku catat.\nBagaimana tren gula?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Catatanmu bisa membantu melihat pola yang tercatat. Data contoh ini belum mewakili makanan yang belum kamu catat.',
                    style: TextStyle(
                      color: Color(0xFF142625),
                      fontSize: 17,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Konteks: catatan hari ini · data contoh',
                    style: TextStyle(color: Color(0xFF5E7170), fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  const _Prompt(text: 'Makanan apa yang sering tercatat?'),
                  const _Prompt(text: 'Bagaimana pola gula di catatanku?'),
                ] else ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Tanya tentang pilihan makanan, porsi, atau kandungan gizi. Jawaban memakai data nutrisi yang tersedia.',
                    style: TextStyle(
                      color: Color(0xFF5E7170),
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const _Prompt(text: 'Bagaimana membandingkan dua camilan?'),
                  const _Prompt(
                    text: 'Apa yang perlu diperhatikan pada minuman?',
                  ),
                ],
              ],
            ),
          ),
          if (showConversation)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Tulis pertanyaanmu…',
                  filled: true,
                  fillColor: const Color(0xFFF3F9F8),
                  suffixIcon: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.send, color: Color(0xFF0B6663)),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFE6F4F3),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF0B6663), fontSize: 14),
          ),
        ),
        const Icon(Icons.arrow_forward, size: 18, color: Color(0xFF0B6663)),
      ],
    ),
  );
}
