import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:han_viet_duo/data/han_character.dart';
import 'package:han_viet_duo/data/models/cjk_character.dart';
import 'package:han_viet_duo/main.dart';
import 'package:han_viet_duo/state/app_state.dart';
import 'package:han_viet_duo/widgets/multilingual_audio_bar.dart';

void main() {
  testWidgets('HanVietApp root widget instantiates properly', (WidgetTester tester) async {
    const app = HanVietApp();
    expect(app, isA<HanVietApp>());
  });

  testWidgets('MultilingualAudioBar displays Vietnamese default and supplementary pill', (WidgetTester tester) async {
    const testChar = HanCharacter(
      character: '一',
      hanVietReading: 'nhất',
      meaning: 'Một, số một',
      radical: 'Nhất (一)',
      strokeCount: 1,
      type: CharacterType.han,
      examples: ['Nhất định', 'Thống nhất'],
    );

    // 1. Kiểm tra khi chưa chọn tiếng phụ: chỉ hiển thị nút Hán-Việt mặc định
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MultilingualAudioBar(
            character: testChar,
            initialLanguage: SupplementaryLanguage.none,
          ),
        ),
      ),
    );

    expect(find.text('Hán-Việt'), findsOneWidget);
    expect(find.text('nhất'), findsOneWidget);
    expect(find.text('Pinyin'), findsNothing);

    // 2. Kiểm tra khi chọn tiếng Quan thoại (Pinyin): nút Pinyin xuất hiện bên cạnh nút Hán-Việt
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MultilingualAudioBar(
            character: testChar,
            initialLanguage: SupplementaryLanguage.mandarin,
          ),
        ),
      ),
    );

    expect(find.text('Hán-Việt'), findsOneWidget);
    expect(find.text('Pinyin'), findsOneWidget);
  });

  testWidgets('MultilingualAudioBar updates dynamically on didUpdateWidget', (WidgetTester tester) async {
    const testChar = HanCharacter(
      character: '一',
      hanVietReading: 'nhất',
      meaning: 'Một, số một',
      radical: 'Nhất (一)',
      strokeCount: 1,
      type: CharacterType.han,
      examples: ['Nhất định', 'Thống nhất'],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MultilingualAudioBar(
            character: testChar,
            initialLanguage: SupplementaryLanguage.none,
          ),
        ),
      ),
    );
    expect(find.text('Hán-Việt'), findsOneWidget);
    expect(find.text("On'yomi"), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MultilingualAudioBar(
            character: testChar,
            initialLanguage: SupplementaryLanguage.japanese,
          ),
        ),
      ),
    );
    expect(find.text('Hán-Việt'), findsOneWidget);
    expect(find.text("On'yomi"), findsOneWidget);
  });

  testWidgets('MultilingualAudioBar respects AppState supplementaryLanguage', (WidgetTester tester) async {
    final appState = AppState();
    appState.supplementaryLanguage = SupplementaryLanguage.mandarin;

    const testChar = HanCharacter(
      character: '一',
      hanVietReading: 'nhất',
      meaning: 'Một, số một',
      radical: 'Nhất (一)',
      strokeCount: 1,
      type: CharacterType.han,
      examples: ['Nhất định', 'Thống nhất'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultilingualAudioBar(
            character: testChar,
            appState: appState,
          ),
        ),
      ),
    );

    expect(find.text('Hán-Việt'), findsOneWidget);
    expect(find.text('Pinyin'), findsOneWidget);
  });
}
