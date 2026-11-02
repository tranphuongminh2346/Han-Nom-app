import 'dart:convert';
import 'package:flutter/services.dart';

import '../data/models/cjk_character.dart';

/// Kho dữ liệu CJK đồng bộ nạp sẵn từ master_dictionary.json.
/// Đảm bảo mọi màn hình (Bài học, Flashcard, Từ điển, Bảng viết)
/// đều truy xuất tức thời Pinyin, Katakana On'yomi mà không bị trễ hay null.
class CjkCatalogue {
  static final Map<String, CjkCharacter> _records = {};
  static bool _isLoaded = false;

  static bool get isLoaded => _isLoaded;

  static Future<void> init() async {
    if (_isLoaded) return;
    try {
      final raw = await rootBundle.loadString('assets/data/master_dictionary.json');
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            try {
              final record = CjkCharacter.fromMap(Map<String, dynamic>.from(item));
              if (record.charTraditional.trim().isNotEmpty) {
                _records[record.charTraditional.trim()] = record;
              }
              if (record.charSimplified.trim().isNotEmpty) {
                _records[record.charSimplified.trim()] = record;
              }
              if (record.charShinjitai.trim().isNotEmpty) {
                _records[record.charShinjitai.trim()] = record;
              }
            } catch (_) {}
          }
        }
      }
      _isLoaded = true;
    } catch (_) {}
  }

  static CjkCharacter? get(String? symbol) {
    if (symbol == null || symbol.trim().isEmpty) return null;
    return _records[symbol.trim()];
  }

  static String getHanViet(String symbol) {
    final record = get(symbol);
    if (record != null && record.readingsHanViet.isNotEmpty) {
      return record.readingsHanViet.first;
    }
    return '';
  }

  static String getPinyin(String symbol) {
    final record = get(symbol);
    if (record != null && record.readingsPinyin.isNotEmpty) {
      return record.readingsPinyin.first;
    }
    return '';
  }

  static String getOnyomi(String symbol) {
    final record = get(symbol);
    if (record != null && record.readingsOnyomi.isNotEmpty) {
      return record.readingsOnyomi.first;
    }
    return '';
  }

  static String getHanja(String symbol) {
    final record = get(symbol);
    if (record != null && record.readingsHanja.isNotEmpty) {
      return record.readingsHanja.first;
    }
    return '';
  }

  static String getJyutping(String symbol) {
    final record = get(symbol);
    if (record != null && record.readingsJyutping.isNotEmpty) {
      return record.readingsJyutping.first;
    }
    return '';
  }
}
