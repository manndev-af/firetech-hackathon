import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({
    super.key,
    this.showConversation = false,
    this.initialMode,
  });

  final bool showConversation;
  final String? initialMode;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _ChatMessage {
  const _ChatMessage({
    required this.isUser,
    required this.text,
    required this.time,
  });

  final bool isUser;
  final String text;
  final DateTime time;
}

class _AssistantScreenState extends State<AssistantScreen> {
  late bool _conversationActive;
  late String _mode;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _conversationActive = widget.showConversation;
    _mode = widget.initialMode ?? (widget.showConversation ? 'pattern' : 'general');
    _initMessages();
  }

  void _initMessages() {
    final now = DateTime.now();
    if (_mode == 'pattern') {
      _messages.addAll([
        _ChatMessage(
          isUser: true,
          text: 'Lihat pola makanan yang sering aku catat.\nBagaimana tren gula?',
          time: now.subtract(const Duration(minutes: 2)),
        ),
        _ChatMessage(
          isUser: false,
          text:
              'Catatanmu bisa membantu melihat pola yang tercatat. Data contoh ini belum mewakili makanan yang belum kamu catat.\n\n'
              'Berdasarkan riwayat konsumsimu:\n'
              '• Asupan protein terjaga dengan konsisten dari makanan utama.\n'
              '• Kandungan gula terakumulasi terutama dari camilan kemasan dan minuman sore.\n'
              '• Natrium masih dalam ambang batas harian yang aman.\n\n'
              'Saran: Kamu bisa menukar minuman manis sore dengan teh tawar atau infused water untuk menjaga fokus gulamu.',
          time: now.subtract(const Duration(minutes: 1)),
        ),
      ]);
    } else if (_mode == 'compare') {
      _messages.addAll([
        _ChatMessage(
          isUser: true,
          text:
              'Bantu aku membandingkan Pilihan A dan Pilihan B. Mending pilih yang mana sesuai fokusku?',
          time: now.subtract(const Duration(minutes: 2)),
        ),
        _ChatMessage(
          isUser: false,
          text:
              'Berdasarkan perbandingan dua pilihan makanan/minumanmu:\n\n'
              '• Pilihan B: Mengandung 6 g gula dan 3 g protein (90 kkal).\n'
              '• Pilihan A: Mengandung 12 g gula dan 4 g protein (130 kkal).\n\n'
              'Trade-off Utama:\n'
              'Pilihan B memotong gula hingga 50%, sedangkan Pilihan A hanya unggul 1 g protein namun membawa tambahan 6 g gula.\n\n'
              'Kesimpulan (Mending yang mana?):\n'
              'Jika prioritasmu adalah membatasi gula, Pilihan B jauh lebih rasional. Namun jika kamu baru selesai berolahraga berat dan butuh asupan protein segera, Pilihan A bisa dipertimbangkan.',
          time: now.subtract(const Duration(minutes: 1)),
        ),
      ]);
    } else {
      _messages.add(
        _ChatMessage(
          isUser: false,
          text:
              'Halo! Saya asisten nutrisi NutriSee. Kamu bisa bertanya tentang kandungan makanan, porsi, atau trade-off gizi berdasarkan preferensimu.\n\n'
              'Ada makanan atau minuman yang sedang kamu pertimbangkan hari ini?',
          time: now,
        ),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String query) {
    final text = query.trim();
    if (text.isEmpty) return;
    _textController.clear();

    setState(() {
      _conversationActive = true;
      _messages.add(
        _ChatMessage(isUser: true, text: text, time: DateTime.now()),
      );
      _isTyping = true;
    });
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final reply = _generateReply(text);
      setState(() {
        _isTyping = false;
        _messages.add(
          _ChatMessage(isUser: false, text: reply, time: DateTime.now()),
        );
      });
      _scrollToBottom();
    });
  }

  String _generateReply(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('gula') || lower.contains('sugar')) {
      return 'Mengenai asupan gula: Batas aman konsumsi harian menurut Kemenkes RI adalah 50 gram (sekitar 4 sendok makan). Saat memilih makanan kemasan, perhatikan nilai "Gula Total" per takaran saji dan hindari pemanis tambahan seperti sirup jagung tinggi fruktosa.';
    }
    if (lower.contains('protein')) {
      return 'Untuk target protein: Kebutuhan umum orang dewasa adalah sekitar 0.8–1.2 g per kg berat badan. Sumber protein berkualitas tinggi yang mudah didapat antara lain dada ayam, telur rebus, tahu, tempe, dan Greek yogurt.';
    }
    if (lower.contains('camilan') || lower.contains('snack')) {
      return 'Memilih camilan sehat: Utamakan makanan yang kaya serat atau protein untuk mempertahankan rasa kenyang lebih lama tanpa memicu lonjakan gula darah, seperti kacang sangrai tawar, potongan buah segar, atau yogurt tanpa pemanis.';
    }
    if (lower.contains('minuman')) {
      return 'Perhatian pada minuman: Kalori dari minuman cair sering kali tidak memicu rasa kenyang yang setara dengan makanan padat. Cek selalu label takaran saji, karena satu botol minuman sering kali mengandung 2 hingga 3 sajian.';
    }
    if (lower.contains('sering') || lower.contains('catatan') || lower.contains('pola')) {
      return 'Berdasarkan pola catatanmu, sebagian besar kalori berasal dari makanan utama siang hari. Menjaga keseimbangan antara lauk berprotein dan sayuran serat adalah kunci untuk menjaga stabilitas energimu sepanjang hari.';
    }
    return 'Pertanyaan yang tepat! Dalam prinsip Personalized Nutrition Trade-Off, setiap makanan memiliki kelebihan dan kekurangan nutrisi. Pilihlah makanan yang paling selaras dengan prioritas utamamu: membatasi gula, memantau natrium, atau mencukupi kebutuhan protein harian.';
  }

  @override
  Widget build(BuildContext context) {
    final showChatInput = _conversationActive;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed top app bar: tombol kembali dan identitas roomchat tetap di atas (tidak ikut ter-scroll)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 20, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Asisten nutrisi',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _conversationActive && _mode == 'pattern'
                              ? 'Fokus gula · pola dari catatanmu'
                              : _conversationActive && _mode == 'compare'
                              ? 'Perbandingan dua pilihan · trade-off AI'
                              : 'Pilih makanan yang ingin kamu pahami',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_conversationActive) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Text(
                        'Tanya tentang pilihan makanan, porsi, atau kandungan gizi. Jawaban memakai data nutrisi yang tersedia.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Pilih topik pertanyaan cepat:',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Prompt(
                      text: 'Bagaimana membandingkan dua camilan?',
                      onTap: () => _sendMessage('Bagaimana membandingkan dua camilan?'),
                    ),
                    _Prompt(
                      text: 'Apa yang perlu diperhatikan pada minuman?',
                      onTap: () => _sendMessage('Apa yang perlu diperhatikan pada minuman?'),
                    ),
                    _Prompt(
                      text: 'Berapa batas konsumsi gula harian?',
                      onTap: () => _sendMessage('Berapa batas konsumsi gula harian?'),
                    ),
                    _Prompt(
                      text: 'Tips memilih makanan tinggi protein',
                      onTap: () => _sendMessage('Tips memilih makanan tinggi protein'),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() => _conversationActive = true);
                        _scrollToBottom();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.heroBackground,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                      label: const Text('Mulai Tulis Pertanyaan'),
                    ),
                  ] else ...[
                    if (_mode == 'pattern') ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Konteks: catatan hari ini · data contoh',
                          style: TextStyle(
                            color: AppColors.heroBackground,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    for (final msg in _messages)
                      _MessageBubble(message: msg),
                    if (_isTyping) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'NutriSee sedang menyusun jawaban…',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Pertanyaan cepat:',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_mode == 'pattern') ...[
                      _Prompt(
                        text: 'Makanan apa yang sering tercatat?',
                        onTap: () => _sendMessage('Makanan apa yang sering tercatat?'),
                      ),
                      _Prompt(
                        text: 'Bagaimana pola gula di catatanku?',
                        onTap: () => _sendMessage('Bagaimana pola gula di catatanku?'),
                      ),
                    ] else if (_mode == 'compare') ...[
                      _Prompt(
                        text: 'Mending mana untuk sarapan?',
                        onTap: () => _sendMessage('Mending mana untuk sarapan?'),
                      ),
                      _Prompt(
                        text: 'Alternatif minuman lain yang rendah gula',
                        onTap: () => _sendMessage('Alternatif minuman lain yang rendah gula'),
                      ),
                    ] else ...[
                      _Prompt(
                        text: 'Berapa batas konsumsi gula harian?',
                        onTap: () => _sendMessage('Berapa batas konsumsi gula harian?'),
                      ),
                      _Prompt(
                        text: 'Tips memilih makanan tinggi protein',
                        onTap: () => _sendMessage('Tips memilih makanan tinggi protein'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
            if (showChatInput)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        onSubmitted: _sendMessage,
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: 'Tulis pertanyaanmu…',
                          hintStyle: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(color: AppColors.border),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: AppColors.border),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: AppColors.heroBackground,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        tooltip: 'Kirim',
                        onPressed: () => _sendMessage(_textController.text),
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 310),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUser ? AppColors.heroBackground : Colors.white,
            borderRadius: BorderRadius.circular(20).copyWith(
              bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
              bottomLeft: !isUser ? const Radius.circular(4) : const Radius.circular(20),
            ),
            border: isUser ? null : Border.all(color: AppColors.border),
            boxShadow: isUser
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'NutriSee AI',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.text, this.onTap});
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: AppColors.mint,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 16,
                color: AppColors.primaryDark,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: AppColors.primaryDark,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
