import 'package:flutter/material.dart';

import '../core/cjk_catalogue.dart';
import '../core/theme/app_colors.dart';
import '../data/han_character.dart';
import '../data/models/cjk_character.dart';
import '../services/tts_service.dart';
import '../state/app_state.dart';

/// Thanh phát âm đa ngôn ngữ:
/// - Mặc định luôn có nút âm tiếng Việt (Hán-Việt).
/// - Khi chọn ngôn ngữ (Pinyin, On'yomi, Hanja, Quảng Đông), nút nghe ngôn ngữ đó sẽ xuất hiện ngay bên cạnh âm Việt.
/// - Có nút chọn/đổi nhanh ngôn ngữ tiện lợi.
class MultilingualAudioBar extends StatefulWidget {
  final HanCharacter? character;
  final String? characterSymbol;
  final String? hanVietReading;
  final CjkCharacter? cjkRecord;
  final bool compact;
  final AppState? appState;
  final SupplementaryLanguage? initialLanguage;
  final bool showAllByDefault;

  const MultilingualAudioBar({
    super.key,
    this.character,
    this.characterSymbol,
    this.hanVietReading,
    this.cjkRecord,
    this.compact = false,
    this.appState,
    this.initialLanguage,
    this.showAllByDefault = false,
  });

  @override
  State<MultilingualAudioBar> createState() => _MultilingualAudioBarState();
}

class _MultilingualAudioBarState extends State<MultilingualAudioBar> {
  late SupplementaryLanguage _currentLanguage;
  late bool _showAll;

  String get _symbol => widget.character?.character ?? widget.characterSymbol ?? '';
  String get _reading {
    final direct = widget.character?.hanVietReading ?? widget.hanVietReading;
    if (direct != null && direct.trim().isNotEmpty) return direct.trim();
    if (_symbol.isNotEmpty) {
      final catalogReading = CjkCatalogue.getHanViet(_symbol);
      if (catalogReading.isNotEmpty) return catalogReading;
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.initialLanguage ??
        widget.appState?.supplementaryLanguage ??
        SupplementaryLanguage.none;
    _showAll = widget.showAllByDefault;
  }

  @override
  void didUpdateWidget(covariant MultilingualAudioBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLanguage != oldWidget.initialLanguage &&
        widget.initialLanguage != null) {
      _currentLanguage = widget.initialLanguage!;
    } else if (widget.appState != null &&
        widget.appState!.supplementaryLanguage != oldWidget.appState?.supplementaryLanguage) {
      _currentLanguage = widget.appState!.supplementaryLanguage;
    }
  }

  void _selectLanguage(SupplementaryLanguage lang) {
    setState(() {
      _showAll = false;
      _currentLanguage = lang;
    });
    if (widget.appState != null) {
      widget.appState!.setSupplementaryLanguage(lang);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_symbol.isEmpty) return const SizedBox.shrink();

    final cjk = widget.cjkRecord ?? CjkCatalogue.get(_symbol);
    final pinyin = cjk?.readingsPinyin.isNotEmpty == true ? cjk!.readingsPinyin.first : '';
    final onyomi = cjk?.readingsOnyomi.isNotEmpty == true ? cjk!.readingsOnyomi.first : '';
    final hanja = cjk?.readingsHanja.isNotEmpty == true ? cjk!.readingsHanja.first : '';
    final jyutping = cjk?.readingsJyutping.isNotEmpty == true ? cjk!.readingsJyutping.first : '';

    return AnimatedBuilder(
      animation: TtsService.instance,
      builder: (context, _) {
        final active = TtsService.instance.activeLanguage;
        final isSpeaking = TtsService.instance.isSpeaking;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. 🇻🇳 Âm mặc định: Luôn luôn là Tiếng Việt (Hán-Việt)
              _AudioPill(
                flag: '🇻🇳',
                label: 'Hán-Việt',
                sublabel: _reading.isNotEmpty ? _reading : null,
                isActive: isSpeaking && active == TtsLanguage.vietnamese,
                onTap: () {
                  final textToSpeak = _reading.isNotEmpty ? _reading : _symbol;
                  if (textToSpeak.isNotEmpty) {
                    TtsService.instance.speakVietnamese(textToSpeak);
                  }
                },
                compact: widget.compact,
              ),

              const SizedBox(width: 8),

              // 2. Chế độ hiển thị: Hoặc hiện tất cả, hoặc hiện nút thứ tiếng được chọn ngay bên cạnh âm Việt
              if (_showAll) ...[
                // 🇨🇳 Pinyin
                _AudioPill(
                  flag: '🇨🇳',
                  label: 'Pinyin',
                  sublabel: pinyin.isNotEmpty ? pinyin : null,
                  isActive: isSpeaking && active == TtsLanguage.mandarin,
                  onTap: () => TtsService.instance.speakChinese(_symbol),
                  compact: widget.compact,
                ),
                const SizedBox(width: 8),
                // 🇯🇵 On'yomi
                _AudioPill(
                  flag: '🇯🇵',
                  label: "On'yomi",
                  sublabel: onyomi.isNotEmpty ? onyomi : null,
                  isActive: isSpeaking && active == TtsLanguage.japanese,
                  onTap: () => TtsService.instance.speakJapanese(onyomi.isNotEmpty ? onyomi : _symbol),
                  compact: widget.compact,
                ),
                const SizedBox(width: 8),
                // 🇰🇷 Hanja
                _AudioPill(
                  flag: '🇰🇷',
                  label: 'Hanja',
                  sublabel: hanja.isNotEmpty ? hanja : 'Sắp có',
                  isActive: isSpeaking && active == TtsLanguage.korean,
                  onTap: () {
                    if (hanja.isNotEmpty) {
                      TtsService.instance.speakKorean(hanja);
                    } else {
                      _showUnavailableToast('Hán-Hàn (Hanja)');
                    }
                  },
                  compact: widget.compact,
                ),
                const SizedBox(width: 8),
                // 🇭🇰 Quảng Đông
                _AudioPill(
                  flag: '🇭🇰',
                  label: 'Quảng Đông',
                  sublabel: jyutping.isNotEmpty ? jyutping : 'Sắp có',
                  isActive: isSpeaking && active == TtsLanguage.cantonese,
                  onTap: () {
                    if (jyutping.isNotEmpty) {
                      TtsService.instance.speakCantonese(jyutping);
                    } else {
                      _showUnavailableToast('Quảng Đông (Jyutping)');
                    }
                  },
                  compact: widget.compact,
                ),
              ] else ...[
                // Hiển thị nút ngôn ngữ đã chọn BÊN CẠNH ÂM VIỆT
                if (_currentLanguage == SupplementaryLanguage.mandarin) ...[
                  _AudioPill(
                    flag: '🇨🇳',
                    label: 'Pinyin',
                    sublabel: pinyin.isNotEmpty ? pinyin : null,
                    isActive: isSpeaking && active == TtsLanguage.mandarin,
                    onTap: () => TtsService.instance.speakChinese(_symbol),
                    compact: widget.compact,
                  ),
                ] else if (_currentLanguage == SupplementaryLanguage.japanese) ...[
                  _AudioPill(
                    flag: '🇯🇵',
                    label: "On'yomi",
                    sublabel: onyomi.isNotEmpty ? onyomi : null,
                    isActive: isSpeaking && active == TtsLanguage.japanese,
                    onTap: () => TtsService.instance.speakJapanese(onyomi.isNotEmpty ? onyomi : _symbol),
                    compact: widget.compact,
                  ),
                ] else if (_currentLanguage == SupplementaryLanguage.hanja) ...[
                  _AudioPill(
                    flag: '🇰🇷',
                    label: 'Hanja',
                    sublabel: hanja.isNotEmpty ? hanja : 'Sắp có',
                    isActive: isSpeaking && active == TtsLanguage.korean,
                    onTap: () {
                      if (hanja.isNotEmpty) {
                        TtsService.instance.speakKorean(hanja);
                      } else {
                        _showUnavailableToast('Hán-Hàn (Hanja)');
                      }
                    },
                    compact: widget.compact,
                  ),
                ] else if (_currentLanguage == SupplementaryLanguage.cantonese) ...[
                  _AudioPill(
                    flag: '🇭🇰',
                    label: 'Quảng Đông',
                    sublabel: jyutping.isNotEmpty ? jyutping : 'Sắp có',
                    isActive: isSpeaking && active == TtsLanguage.cantonese,
                    onTap: () {
                      if (jyutping.isNotEmpty) {
                        TtsService.instance.speakCantonese(jyutping);
                      } else {
                        _showUnavailableToast('Quảng Đông (Jyutping)');
                      }
                    },
                    compact: widget.compact,
                  ),
                ],
              ],

              const SizedBox(width: 8),

              // 3. Nút menu đổi ngôn ngữ / chọn tiếng khác
              PopupMenuButton<String>(
                tooltip: 'Chọn ngôn ngữ phát âm bổ sung',
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                position: PopupMenuPosition.under,
                onSelected: (value) {
                  switch (value) {
                    case 'mandarin':
                      _selectLanguage(SupplementaryLanguage.mandarin);
                      TtsService.instance.speakChinese(_symbol);
                      break;
                    case 'japanese':
                      _selectLanguage(SupplementaryLanguage.japanese);
                      TtsService.instance.speakJapanese(onyomi.isNotEmpty ? onyomi : _symbol);
                      break;
                    case 'hanja':
                      _selectLanguage(SupplementaryLanguage.hanja);
                      if (hanja.isNotEmpty) {
                        TtsService.instance.speakKorean(hanja);
                      } else {
                        _showUnavailableToast('Hán-Hàn (Hanja)');
                      }
                      break;
                    case 'cantonese':
                      _selectLanguage(SupplementaryLanguage.cantonese);
                      if (jyutping.isNotEmpty) {
                        TtsService.instance.speakCantonese(jyutping);
                      } else {
                        _showUnavailableToast('Quảng Đông (Jyutping)');
                      }
                      break;
                    case 'none':
                      _selectLanguage(SupplementaryLanguage.none);
                      break;
                    case 'all':
                      setState(() => _showAll = true);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'mandarin',
                    child: Row(children: [
                      Text('🇨🇳', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 10),
                      Text('Quan thoại (Pinyin)', style: TextStyle(fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'japanese',
                    child: Row(children: [
                      Text('🇯🇵', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 10),
                      Text("Hán-Nhật (On'yomi)", style: TextStyle(fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'hanja',
                    child: Row(children: [
                      Text('🇰🇷', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 10),
                      Text('Hán-Hàn (Hanja)', style: TextStyle(fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'cantonese',
                    child: Row(children: [
                      Text('🇭🇰', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 10),
                      Text('Quảng Đông (Jyutping)', style: TextStyle(fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'all',
                    child: Row(children: [
                      Icon(Icons.view_carousel_rounded, size: 18, color: kGreen),
                      SizedBox(width: 10),
                      Text('Hiện tất cả các thứ tiếng', style: TextStyle(fontWeight: FontWeight.w700, color: kGreen)),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'none',
                    child: Row(children: [
                      Icon(Icons.volume_mute_rounded, size: 18, color: Colors.black54),
                      SizedBox(width: 10),
                      Text('Chỉ nghe âm Hán-Việt', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                    ]),
                  ),
                ],
                child: Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDDE6DD)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.compact ? 8 : 10,
                      vertical: widget.compact ? 6 : 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.language_rounded, size: 16, color: kGreen),
                        const SizedBox(width: 4),
                        Text(
                          _showAll
                              ? 'Tất cả'
                              : _currentLanguage == SupplementaryLanguage.none
                                  ? '+ Thêm tiếng'
                                  : 'Đổi tiếng',
                          style: TextStyle(
                            fontSize: widget.compact ? 11 : 12,
                            fontWeight: FontWeight.w800,
                            color: kGreen,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded, size: 18, color: kGreen),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUnavailableToast(String languageName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dữ liệu âm đọc $languageName đang được biên tập cho chữ này.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _AudioPill extends StatelessWidget {
  final String flag;
  final String label;
  final String? sublabel;
  final bool isActive;
  final VoidCallback onTap;
  final bool compact;

  const _AudioPill({
    required this.flag,
    required this.label,
    this.sublabel,
    required this.isActive,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? kGreenLight : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive ? kGreen : const Color(0xFFDDE6DD),
          width: isActive ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 6 : 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(flag, style: TextStyle(fontSize: compact ? 14 : 16)),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: compact ? 11 : 12,
                          fontWeight: FontWeight.w800,
                          color: isActive ? kGreen : const Color(0xFF2B4135),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isActive ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                        size: compact ? 13 : 15,
                        color: isActive ? kGreen : Colors.black45,
                      ),
                    ],
                  ),
                  if (sublabel != null && sublabel!.trim().isNotEmpty && !compact) ...[
                    const SizedBox(height: 1),
                    Text(
                      sublabel!,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
