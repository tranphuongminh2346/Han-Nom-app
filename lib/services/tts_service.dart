import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsLanguage {
  vietnamese,
  mandarin,
  cantonese,
  japanese,
  korean,
  english,
}

extension TtsLanguageDetails on TtsLanguage {
  String get code {
    switch (this) {
      case TtsLanguage.vietnamese:
        return 'vi-VN';
      case TtsLanguage.mandarin:
        return 'zh-CN';
      case TtsLanguage.cantonese:
        return 'zh-HK';
      case TtsLanguage.japanese:
        return 'ja-JP';
      case TtsLanguage.korean:
        return 'ko-KR';
      case TtsLanguage.english:
        return 'en-US';
    }
  }

  String get label {
    switch (this) {
      case TtsLanguage.vietnamese:
        return 'Hán-Việt';
      case TtsLanguage.mandarin:
        return 'Pinyin';
      case TtsLanguage.cantonese:
        return 'Quảng Đông';
      case TtsLanguage.japanese:
        return "On'yomi";
      case TtsLanguage.korean:
        return 'Hanja';
      case TtsLanguage.english:
        return 'Tiếng Anh';
    }
  }

  String get flag {
    switch (this) {
      case TtsLanguage.vietnamese:
        return '🇻🇳';
      case TtsLanguage.mandarin:
        return '🇨🇳';
      case TtsLanguage.cantonese:
        return '🇭🇰';
      case TtsLanguage.japanese:
        return '🇯🇵';
      case TtsLanguage.korean:
        return '🇰🇷';
      case TtsLanguage.english:
        return '🇬🇧';
    }
  }
}

class TtsService extends ChangeNotifier {
  static final TtsService instance = TtsService._internal();
  TtsService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  TtsLanguage? _activeLanguage;

  bool get isSpeaking => _isSpeaking;
  TtsLanguage? get activeLanguage => _activeLanguage;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      _flutterTts = FlutterTts();

      _flutterTts!.setStartHandler(() {
        _isSpeaking = true;
        notifyListeners();
      });

      _flutterTts!.setCompletionHandler(() {
        _isSpeaking = false;
        _activeLanguage = null;
        notifyListeners();
      });

      _flutterTts!.setCancelHandler(() {
        _isSpeaking = false;
        _activeLanguage = null;
        notifyListeners();
      });

      _flutterTts!.setErrorHandler((msg) {
        _isSpeaking = false;
        _activeLanguage = null;
        notifyListeners();
        debugPrint('TTS Error: $msg');
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS initialization warning: $e');
    }
  }

  /// Tìm và gán giọng đọc chuẩn xác cho từng ngôn ngữ (đặc biệt quan trọng trên Web & Windows)
  Future<void> _applyVoiceForLanguage(TtsLanguage language) async {
    try {
      final dynamic voices = await _flutterTts?.getVoices;
      if (voices is List && voices.isNotEmpty) {
        Map<String, String>? chosenVoice;
        for (final v in voices) {
          if (v is! Map) continue;
          final locale = (v['locale'] ?? '').toString().toLowerCase().replaceAll('_', '-');
          final name = (v['name'] ?? '').toString().toLowerCase();

          final isMatch = switch (language) {
            TtsLanguage.vietnamese =>
              locale.startsWith('vi') ||
              name.contains('vietnam') ||
              name.contains('viet') ||
              name.contains('tieng viet') ||
              name.contains('microsoft an') ||
              name.contains('microsoft nam') ||
              name.contains('an nhi') ||
              name.contains('hoai my') ||
              name.contains('nam minh'),
            TtsLanguage.mandarin =>
              locale == 'zh-cn' || locale == 'cmn-cn' || locale == 'cmn-hans-cn' || (locale.startsWith('zh') && !locale.contains('hk') && !locale.contains('tw')) || name.contains('mandarin') || name.contains('putonghua') || (name.contains('chinese') && !name.contains('hong kong') && !name.contains('cantonese')) || name.contains('xiaoxiao'),
            TtsLanguage.japanese =>
              locale.startsWith('ja') || name.contains('japan') || name.contains('nanami') || name.contains('keita') || name.contains('ichirou'),
            TtsLanguage.korean =>
              locale.startsWith('ko') || name.contains('korea') || name.contains('sunhi') || name.contains('injoon'),
            TtsLanguage.cantonese =>
              locale.contains('zh-hk') || locale.contains('yue') || name.contains('cantonese') || name.contains('hong kong') || name.contains('hiumaan'),
            TtsLanguage.english =>
              locale.startsWith('en') || name.contains('english'),
          };

          if (isMatch) {
            chosenVoice = {
              'name': v['name'].toString(),
              'locale': v['locale'].toString(),
            };
            break;
          }
        }

        if (chosenVoice != null) {
          await _flutterTts!.setVoice(chosenVoice);
          await _flutterTts!.setLanguage(chosenVoice['locale']!);
          return;
        }
      }
    } catch (e) {
      debugPrint('Voice selection warning: $e');
    }

    // Dự phòng mã ngôn ngữ ISO chuẩn
    await _flutterTts!.setLanguage(language.code);
  }

  Future<void> speakWithLanguage(String text, TtsLanguage language) async {
    try {
      await init();
      if (_flutterTts == null || text.trim().isEmpty) return;

      await _flutterTts!.stop();
      _activeLanguage = language;
      _isSpeaking = true;
      notifyListeners();

      await _applyVoiceForLanguage(language);

      // Tốc độ phát âm tối ưu cho người học ngôn ngữ
      final rate = language == TtsLanguage.vietnamese ? 0.48 : 0.42;
      await _flutterTts!.setSpeechRate(rate);
      await _flutterTts!.setPitch(1.0);
      await _flutterTts!.speak(text);
    } catch (e) {
      _isSpeaking = false;
      _activeLanguage = null;
      notifyListeners();
      debugPrint('Error speaking ${language.name}: $e');
    }
  }

  /// Phát âm tiếng Việt (cho âm Hán-Việt hoặc nghĩa)
  Future<void> speakVietnamese(String text) async {
    await speakWithLanguage(text, TtsLanguage.vietnamese);
  }

  /// Phát âm tiếng Trung Quan thoại (Mandarin / Pinyin)
  Future<void> speakChinese(String text) async {
    await speakWithLanguage(text, TtsLanguage.mandarin);
  }

  /// Phát âm tiếng Quảng Đông (Cantonese / Jyutping)
  Future<void> speakCantonese(String text) async {
    await speakWithLanguage(text, TtsLanguage.cantonese);
  }

  /// Phát âm tiếng Nhật (On'yomi / Kun'yomi bằng chữ Katakana)
  Future<void> speakJapanese(String text) async {
    await speakWithLanguage(text, TtsLanguage.japanese);
  }

  /// Phát âm tiếng Hàn (Sino-Korean / Hanja bằng Hangul)
  Future<void> speakKorean(String text) async {
    await speakWithLanguage(text, TtsLanguage.korean);
  }

  /// Phát âm tiếng Anh (English meaning)
  Future<void> speakEnglish(String text) async {
    await speakWithLanguage(text, TtsLanguage.english);
  }

  Future<void> stop() async {
    try {
      if (_flutterTts != null) {
        await _flutterTts!.stop();
        _isSpeaking = false;
        _activeLanguage = null;
        notifyListeners();
      }
    } catch (_) {}
  }
}
