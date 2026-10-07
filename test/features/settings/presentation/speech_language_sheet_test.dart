import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/speech/di/speech_providers.dart';
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/settings/presentation/widgets/overlays/speech_language_sheet_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

import '../../../support/fake_speech_synthesizer.dart';

// Study speech spec §6, D5, D12.

final _en = lookupAppLocalizations(const Locale('en'));

/// Opens the sheet over a page; the returned future completes with the pick
/// once a row is tapped.
Future<Future<SpeechLanguage?>> _open(
  WidgetTester tester, {
  required Set<String> available,
  SpeechLanguage selected = SpeechLanguage.enUs,
}) async {
  late Future<SpeechLanguage?> picked;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        speechSynthesizerProvider.overrideWithValue(
          FakeSpeechSynthesizer(available: available),
        ),
      ],
      child: MaterialApp(
        theme: buildLightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  picked = showSpeechLanguageSheet(context, selected: selected),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return picked;
}

void main() {
  testWidgets('every language is a row, the selected one marked, the ones '
      'the device lacks described (D5)', (tester) async {
    await _open(tester, available: {'en-US', 'ko-KR'});

    expect(
      find.byType(MxOptionRow),
      findsNWidgets(SpeechLanguage.values.length),
    );
    final selected = tester.widget<MxOptionRow>(
      find.widgetWithText(MxOptionRow, _en.speechLanguageEnUs),
    );
    expect(selected.isSelected, isTrue);
    expect(find.text(_en.settingsSpeechLanguageMissing), findsNWidgets(8));
    final korean = tester.widget<MxOptionRow>(
      find.widgetWithText(MxOptionRow, _en.speechLanguageKoKr),
    );
    expect(korean.description, isNull);
  });

  testWidgets('a tap returns the language and closes the sheet', (
    tester,
  ) async {
    final picked = await _open(tester, available: const {});

    await tester.tap(find.text(_en.speechLanguageJaJp));
    await tester.pumpAndSettle();

    expect(await picked, SpeechLanguage.jaJp);
    expect(find.byType(MxOptionRow), findsNothing);
  });

  testWidgets('an engine that reports no languages marks nothing', (
    tester,
  ) async {
    await _open(tester, available: const {});

    expect(find.text(_en.settingsSpeechLanguageMissing), findsNothing);
  });
}
