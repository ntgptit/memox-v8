import 'package:flutter/material.dart';

import 'dart:async';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/presentation/screens/starter_library_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../../support/library_harness.dart';
import '../../../support/starter_screen_fixtures.dart';

// Screen 03 (FE-B4, UC-STARTER-001): the ten kit states.

final _en = lookupAppLocalizations(const Locale('en'));

/// The root decks copied from the Hangul template, by scheduler.
Future<List<String>> _hangulCopies(LibraryEnv env) async => [
  for (final row
      in await env.db
          .customSelect(
            'SELECT scheduler_type FROM deck WHERE source_template_id = ? '
            'ORDER BY created_at, id',
            variables: [Variable<String>(hangulTemplate.templateId)],
          )
          .get())
    row.read<String>('scheduler_type'),
];

Finder _cardButton(String label) => find.widgetWithText(MxButton, label);

Future<void> _pump(
  WidgetTester tester,
  LibraryEnv env,
  StarterLibraryFake library, {
  ValueChanged<String>? onOpenDeck,
  VoidCallback? onCreateDeck,
}) => pumpLibraryScreen(
  tester,
  env,
  StarterLibraryScreen(
    onOpenDeck: onOpenDeck ?? (_) {},
    onCreateDeck: onCreateDeck ?? () {},
  ),
  overrides: [library.asOverride],
);

/// Taps the Hangul card's add, which is its second button.
Future<void> _addHangul(WidgetTester tester, String label) async {
  await tester.tap(_cardButton(label).last);
  await tester.pumpAndSettle();
}

void main() {
  libraryTest('list: the note, then a card per template with its facts, '
      'its add and what it suggests', (tester, env) async {
    await _pump(tester, env, StarterLibraryFake(env));

    expect(find.text(_en.starterNote), findsOneWidget);
    expect(find.text(everydayTemplate.title), findsOneWidget);
    expect(
      find.text(
        'Korean · Latin · 60 cards · 2 sub-decks · Development fixture',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'English · Vietnamese · 120 cards · 4 sub-decks · '
        'Development fixture',
      ),
      findsOneWidget,
    );
    expect(_cardButton(_en.starterAddToLibrary), findsNWidgets(2));
    expect(find.text(_en.starterSuggests('SM-2')), findsOneWidget);
    expect(find.text(_en.starterSuggests('Eight boxes')), findsOneWidget);
    expect(find.text(_en.starterInLibrary), findsNothing);
  });

  libraryTest('the facts line is all in the person\'s language: the '
      'fixture source is named in Vietnamese too (final review #2)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      StarterLibraryScreen(onOpenDeck: (_) {}, onCreateDeck: () {}),
      locale: const Locale('vi'),
      overrides: [StarterLibraryFake(env).asOverride],
    );

    expect(
      find.text('Tiếng Hàn · Chữ Latinh · 60 thẻ · 2 deck con · Dữ liệu mẫu'),
      findsOneWidget,
    );
    expect(find.textContaining('Development fixture'), findsNothing);
  });

  libraryTest('choose: the sheet preselects the suggested scheduler; the one '
      'picked is the copy\'s, and the toast opens it (added)', (
    tester,
    env,
  ) async {
    String? opened;
    await _pump(
      tester,
      env,
      StarterLibraryFake(env),
      onOpenDeck: (id) => opened = id,
    );
    await _addHangul(tester, _en.starterAddToLibrary);

    expect(find.text(_en.starterSheetTitle(hangulTemplate.title)), findsOne);
    expect(find.text(_en.starterSheetBody(60, 2)), findsOneWidget);
    final sm2 = tester.widget<MxOptionRow>(
      find.widgetWithText(MxOptionRow, 'SM-2'),
    );
    expect(sm2.isSelected, isTrue);
    expect(sm2.description, _en.starterSuggested(_en.starterSm2Description));

    await tester.tap(find.text('Eight boxes').last);
    await tester.pump();
    await tester.tap(find.text(_en.starterAddDeck));
    await tester.pumpAndSettle();

    expect(await _hangulCopies(env), ['eight_box']);
    expect(
      find.text(_en.starterAdded(hangulTemplate.title, 'Eight boxes', 60)),
      findsOneWidget,
    );
    expect(find.text(_en.starterInLibrary), findsOneWidget);
    await tester.tap(find.text(_en.starterOpen));
    await tester.pump();
    final rootId = await env.db
        .customSelect(
          'SELECT id FROM deck WHERE source_template_id = ?',
          variables: [Variable<String>(hangulTemplate.templateId)],
        )
        .getSingle();
    expect(opened, rootId.read<String>('id'));
  });

  libraryTest('adding: the options and Cancel lock and the add spins; the '
      'sheet cannot be dismissed', (tester, env) async {
    final library = StarterLibraryFake(env)..hold = Completer<void>();
    await _pump(tester, env, library);
    await _addHangul(tester, _en.starterAddToLibrary);
    await tester.tap(find.text(_en.starterAddDeck));
    await tester.pump();

    expect(find.byType(MxSpinner), findsOneWidget);
    for (final row in tester.widgetList<MxOptionRow>(
      find.byType(MxOptionRow),
    )) {
      expect(row.onSelected, isNull);
    }
    expect(
      tester.widget<MxButton>(_cardButton(_en.commonCancel)).onPressed,
      isNull,
    );
    await tester.tapAt(const Offset(180, 40));
    await tester.pump();
    expect(find.byType(MxOptionRow), findsNWidgets(2));
    // A drag down does not close it either (final review #1).
    await tester.drag(find.byType(MxOptionRow).first, const Offset(0, 500));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(MxOptionRow), findsNWidgets(2));

    library.hold!.complete();
    await tester.pumpAndSettle();
    expect(library.adds, 1);
    expect(find.byType(MxOptionRow), findsNothing);
  });

  libraryTest('alreadyPresent: a copy made while the sheet was open copies '
      'nothing more', (tester, env) async {
    final library = StarterLibraryFake(env);
    await _pump(tester, env, library);
    await _addHangul(tester, _en.starterAddToLibrary);
    await library.addStarterDeck(
      templateId: hangulTemplate.templateId,
      schedulerType: SchedulerType.sm2,
    );
    await tester.tap(find.text(_en.starterAddDeck));
    await tester.pumpAndSettle();

    expect(find.text(_en.starterAlreadyPresent), findsOneWidget);
    expect(await _hangulCopies(env), ['sm2']);
  });

  libraryTest('secondCopy: a template in the library asks first; Cancel '
      'copies nothing, confirming adds a deck of its own', (tester, env) async {
    final library = StarterLibraryFake(env);
    await library.addStarterDeck(
      templateId: hangulTemplate.templateId,
      schedulerType: SchedulerType.sm2,
    );
    await _pump(tester, env, library);
    await _addHangul(tester, _en.starterAddAnotherCopy);

    expect(find.text(_en.starterSecondCopyTitle), findsOneWidget);
    expect(
      find.text(_en.starterSecondCopyBody(hangulTemplate.title)),
      findsOneWidget,
    );
    await tester.tap(find.text(_en.commonCancel));
    await tester.pumpAndSettle();
    expect(find.byType(MxOptionRow), findsNothing);

    await _addHangul(tester, _en.starterAddAnotherCopy);
    await tester.tap(find.text(_en.starterSecondCopyConfirm));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.starterAddDeck));
    await tester.pumpAndSettle();

    expect(await _hangulCopies(env), ['sm2', 'sm2']);
    expect(
      find.text(_en.starterAdded(hangulTemplate.title, 'SM-2', 60)),
      findsOneWidget,
    );
  });

  libraryTest('addFailed: the sheet stays with the choice and says so; Try '
      'again adds', (tester, env) async {
    final library = StarterLibraryFake(env)..failsAdds = true;
    await _pump(tester, env, library);
    await _addHangul(tester, _en.starterAddToLibrary);
    await tester.tap(find.text('Eight boxes').last);
    await tester.pump();
    await tester.tap(find.text(_en.starterAddDeck));
    await tester.pumpAndSettle();

    expect(find.byType(MxInlineBanner), findsOneWidget);
    expect(find.text(_en.starterAddFailedBody), findsOneWidget);
    expect(
      tester
          .widget<MxOptionRow>(find.widgetWithText(MxOptionRow, 'Eight boxes'))
          .isSelected,
      isTrue,
    );
    expect(await _hangulCopies(env), isEmpty);

    library.failsAdds = false;
    await tester.tap(find.text(_en.starterTryAgain));
    await tester.pumpAndSettle();
    expect(await _hangulCopies(env), ['eight_box']);
    expect(find.byType(MxInlineBanner), findsNothing);
  });

  libraryTest('none: a build without templates offers to create a deck', (
    tester,
    env,
  ) async {
    var creates = 0;
    await _pump(
      tester,
      env,
      StarterLibraryFake(env, templates: const []),
      onCreateDeck: () => creates++,
    );

    expect(find.text(_en.starterNoneTitle), findsOneWidget);
    expect(find.byType(MxEmptyState), findsOneWidget);
    await tester.tap(find.text(_en.starterCreateDeck));
    expect(creates, 1);
  });

  libraryTest('loading, then loadFailed with Retry; the message carries no '
      'failure text', (tester, env) async {
    final loaded = Completer<void>();
    await _pump(
      tester,
      env,
      StarterLibraryFake(env, failsLoad: true, loaded: loaded.future),
    );
    expect(find.bySemanticsLabel(_en.commonLoading), findsOneWidget);

    loaded.complete();
    await tester.pumpAndSettle();
    expect(find.text(_en.starterLoadErrorTitle), findsOneWidget);
    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.textContaining('load failed'), findsNothing);
    expect(find.text(_en.commonRetry), findsOneWidget);
  });

  libraryTest('a template already in the library offers another copy as the '
      'secondary action (critique 2026-09-30)', (tester, env) async {
    final library = StarterLibraryFake(env);
    await library.addStarterDeck(
      templateId: everydayTemplate.templateId,
      schedulerType: everydayTemplate.suggestedScheduler,
    );
    await _pump(tester, env, library);

    expect(
      tester.widget<MxButton>(_cardButton(_en.starterAddAnotherCopy)).tone,
      MxButtonTone.secondary,
    );
    expect(
      tester.widget<MxButton>(_cardButton(_en.starterAddToLibrary)).tone,
      MxButtonTone.primary,
    );
  });

  libraryTest('the fixture note can be hidden, and stays hidden '
      '(critique 2026-09-30)', (tester, env) async {
    await _pump(tester, env, StarterLibraryFake(env));

    await tester.tap(find.byTooltip(_en.commonDismissNote));
    await tester.pumpAndSettle();
    expect(find.text(_en.starterNote), findsNothing);

    await _pump(tester, env, StarterLibraryFake(env));
    await tester.pumpAndSettle();
    expect(find.text(_en.starterNote), findsNothing);
  });

  libraryTest('the algorithm sheet labels its choice in sentence case with a '
      'Required caption (critique 2026-09-30 part 2, P3)', (tester, env) async {
    await _pump(tester, env, StarterLibraryFake(env));
    await _addHangul(tester, _en.starterAddToLibrary);

    final label = find.text(_en.starterSheetAlgorithmLabel);
    final required = find.text(_en.starterSheetRequired);
    final styles = tester.element(label).textStyles;
    expect(tester.widget<Text>(label).style, styles.fieldLabel);
    expect(tester.widget<Text>(required).style, styles.requiredMarker);
  });
}
