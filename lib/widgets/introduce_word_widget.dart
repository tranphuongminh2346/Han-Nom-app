import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/question.dart';
import '../data/models/cjk_character.dart';
import '../state/app_state.dart';
import 'interactive_sentence.dart';
import 'multilingual_audio_bar.dart';

const Color _introGreen = Color(0xFF28664F);
const Color _introBlue = Color(0xFF3186C8);

/// Giao diện giới thiệu từ mới: phát âm đa ngữ, chạm vào chữ để xem tooltip, sau đó chọn nghĩa.
class IntroduceWordWidget extends StatefulWidget {
  final Question question;
  final ValueChanged<String> onSelected;
  final bool enabled;
  final String? selectedAnswer;
  final SupplementaryLanguage supplementaryLanguage;
  final List<CjkCharacter> cjkCharacters;
  final AppState? appState;

  const IntroduceWordWidget({
    super.key,
    required this.question,
    required this.onSelected,
    this.enabled = true,
    this.selectedAnswer,
    this.supplementaryLanguage = SupplementaryLanguage.none,
    this.cjkCharacters = const <CjkCharacter>[],
    this.appState,
  });

  @override
  State<IntroduceWordWidget> createState() => _IntroduceWordWidgetState();
}

class _IntroduceWordWidgetState extends State<IntroduceWordWidget> {
  CjkCharacter? _findCjkRecord(String symbol) {
    for (final c in widget.cjkCharacters) {
      if (c.charTraditional == symbol || c.charSimplified == symbol) return c;
    }
    return null;
  }

  Widget _buildCard(String option) {
    final isSelected = widget.selectedAnswer == option;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEAF2FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? _introBlue : const Color(0xFFDCE4DC),
          width: isSelected ? 2.5 : 1.5,
        ),
        boxShadow: isSelected
            ? const []
            : const [BoxShadow(color: Color(0x16000000), offset: Offset(0, 3), blurRadius: 3)],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.enabled ? () => widget.onSelected(option) : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: Text(
                option,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? _introBlue : const Color(0xFF263A2F),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.question.sentenceTokens ?? const <SentenceToken>[];
    final symbol = widget.question.associatedCharacter;
    final reading = tokens.isNotEmpty ? tokens.first.hanVietReading : null;
    final cjk = _findCjkRecord(symbol);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
          decoration: BoxDecoration(
            color: const Color(0xFFE4F1E8),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFC9E2D0)),
          ),
          child: Column(
            children: [
              const Text(
                'TỪ MỚI',
                style: TextStyle(color: _introGreen, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5),
              ),
              const SizedBox(height: 10),
              InteractiveSentence(
                tokens: tokens,
                supplementaryLanguage: widget.supplementaryLanguage,
                cjkCharacters: widget.cjkCharacters,
              ),
              const SizedBox(height: 12),
              // Thanh phát âm đa ngữ (Việt, Quan thoại, Nhật, Hàn, Quảng Đông)
              MultilingualAudioBar(
                characterSymbol: symbol,
                hanVietReading: reading,
                cjkRecord: cjk,
                appState: widget.appState,
                initialLanguage: widget.supplementaryLanguage,
                compact: true,
              ),
              const SizedBox(height: 8),
              const Text(
                'Chạm chữ để xem tooltip • Chọn loa để nghe phát âm các tiếng',
                textAlign: TextAlign.center,
                style: TextStyle(color: _introGreen, fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'CHỌN NGHĨA TIẾNG VIỆT',
          style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: Colors.black45, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.45,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: widget.question.options.map(_buildCard).toList(),
        ),
      ],
    );
  }
}
