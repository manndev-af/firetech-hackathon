import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SummarySpeech extends ChangeNotifier {
  SummarySpeech({FlutterTts? engine}) : _tts = engine ?? FlutterTts();
  final FlutterTts _tts;
  static final shared = SummarySpeech();
  int _generation = 0;
  String? activeId;

  Future<void> stop() async {
    _generation++;
    activeId = null;
    notifyListeners();
    try {
      await _tts.stop();
    } catch (_) {
      /* Text remains available without an engine. */
    }
  }

  Future<void> speak(String id, String summary) async {
    if (summary.trim().isEmpty || summary.length > 320) {
      throw StateError('Kesimpulan audio belum tersedia.');
    }
    final generation = ++_generation;
    activeId = id;
    notifyListeners();
    try {
      await _tts.stop();
      final voices = await _tts.getVoices;
      final offline = (voices is List ? voices : const [])
          .whereType<Map>()
          .where((voice) {
        final locale = voice['locale'].toString().toLowerCase();
        final features = voice['features']?.toString() ?? '';
        return (locale.startsWith('id-') ||
                locale.startsWith('id_') ||
                locale.startsWith('in-')) &&
            voice['network_required']?.toString() == '0' &&
            !features.contains('notInstalled');
      }).toList();
      if (offline.isEmpty) {
        throw StateError(
          'Pasang suara Bahasa Indonesia offline melalui pengaturan Text-to-Speech perangkat.',
        );
      }
      await _tts.setLanguage(offline.first['locale'].toString());
      await _tts.setVoice({
        'name': offline.first['name'].toString(),
        'locale': offline.first['locale'].toString(),
      });
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.45);
      await _tts.awaitSpeakCompletion(true);
      if (generation != _generation) return;
      activeId = id;
      notifyListeners();
      final result = await _tts.speak(summary);
      if (result != 1) {
        throw StateError(
          'Suara belum dapat diputar. Teks kesimpulan tetap tersedia.',
        );
      }
    } finally {
      if (generation == _generation) {
        activeId = null;
        notifyListeners();
      }
    }
  }
}
