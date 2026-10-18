import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_source_template_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/deck/domain/usecases/create_root_deck_use_case.dart';
import 'package:memox/features/deck/presentation/providers/create_root_deck_use_case_provider.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/create_root_deck_dialog_widget.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

import '../../../support/forui_expect.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

import 'package:forui/forui.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Widget _host() => Scaffold(
  body: Builder(
    builder: (context) => MxButton(
      label: 'Open',
      onPressed: () => showCreateRootDeckDialog(context),
    ),
  ),
);

Future<List<(String, String)>> _decks(LibraryEnv env) async => [
  for (final row
      in await env.db
          .customSelect('SELECT name, scheduler_type FROM deck')
          .get())
    (row.read<String>('name'), row.read<String>('scheduler_type')),
];

/// Decks whose create fails the first way a real database can.
final class _FailingDecks implements DeckRepository {
  @override
  Future<Outcome<DeckEntity, DeckRejection>> createRootDeck({
    required String name,
    required SchedulerType schedulerType,
    DeckSourceTemplate? sourceTemplate,
    DateTime? now,
  }) => Future.error(const UnknownDatabaseFailure(cause: '/data/memox.sqlite'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Decks whose create stays pending until [release].
final class _SlowDecks implements DeckRepository {
  _SlowDecks(this._real);

  final DeckRepository _real;
  final _gate = Completer<void>();
  int calls = 0;

  void release() => _gate.complete();

  @override
  Future<Outcome<DeckEntity, DeckRejection>> createRootDeck({
    required String name,
    required SchedulerType schedulerType,
    DeckSourceTemplate? sourceTemplate,
    DateTime? now,
  }) async {
    calls++;
    await _gate.future;
    return _real.createRootDeck(
      name: name,
      schedulerType: schedulerType,
      sourceTemplate: sourceTemplate,
      now: now,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  /// No scheduler is chosen for the person (BR-SRS-001).
  Future<void> chooseEightBox(WidgetTester tester) async {
    await tester.tap(find.text(_en.deckSchedulerEightBox));
    await tester.pump();
  }

  libraryTest('the name field paints its label once, above the box', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _host());
    await open(tester);

    expect(find.text(_en.deckNameHint), findsOneWidget);
    expect(
      tester.getBottomLeft(find.text(_en.deckNameHint)).dy,
      lessThanOrEqualTo(
        tester.getTopLeft(fieldBox(find.byType(FTextField))).dy,
      ),
    );
  });

  for (final c in [
    (
      name: 'a blank name is refused under the field; nothing is written',
      typed: '',
      refusal: _en.deckRejectionBlankName,
    ),
    (
      name: 'a name longer than 200 characters is refused; nothing is written',
      typed: 'a' * 201,
      refusal: _en.deckRejectionNameTooLong,
    ),
  ]) {
    libraryTest(c.name, (tester, env) async {
      await pumpLibraryScreen(tester, env, _host());
      await open(tester);
      await tester.enterText(find.byType(EditableText), c.typed);
      await chooseEightBox(tester);
      await tester.tap(find.text(_en.deckCreateConfirm));
      await tester.pumpAndSettle();

      expect(find.text(c.refusal), findsOneWidget);
      expect(find.byType(MxDialog), findsOneWidget);
      expect(await _decks(env), isEmpty);
    });
  }

  for (final c
      in <
        ({
          String name,
          String typed,
          String scheduler,
          Future<void> Function(WidgetTester) submit,
          (String, String) stored,
        })
      >[
        (
          name: 'a name and SM-2 create a root deck and close the dialog',
          typed: '  Korean  ',
          scheduler: _en.deckSchedulerSm2,
          submit: (tester) => tester.tap(find.text(_en.deckCreateConfirm)),
          stored: ('Korean', 'sm2'),
        ),
        (
          name: 'the keyboard Done action creates the deck',
          typed: 'Korean',
          scheduler: _en.deckSchedulerEightBox,
          submit: (tester) =>
              tester.testTextInput.receiveAction(TextInputAction.done),
          stored: ('Korean', 'eight_box'),
        ),
      ]) {
    libraryTest(c.name, (tester, env) async {
      await pumpLibraryScreen(tester, env, _host());
      await open(tester);
      await tester.enterText(find.byType(EditableText), c.typed);
      await tester.tap(find.text(c.scheduler));
      await tester.pump();
      await c.submit(tester);
      await tester.pumpAndSettle();

      expect(find.byType(MxDialog), findsNothing);
      expect(await _decks(env), [c.stored]);
    });
  }

  libraryTest('a double tap on Create makes one deck (RF3)', (
    tester,
    env,
  ) async {
    final slow = _SlowDecks(env.decks);
    await pumpLibraryScreen(
      tester,
      env,
      _host(),
      overrides: [
        createRootDeckUseCaseProvider.overrideWithValue(
          CreateRootDeckUseCase(slow),
        ),
      ],
    );
    await open(tester);
    await tester.enterText(find.byType(EditableText), 'Korean');
    await chooseEightBox(tester);
    await tester.tap(find.text(_en.deckCreateConfirm));
    await tester.pump();
    await tester.tap(find.text(_en.deckCreateConfirm), warnIfMissed: false);
    await tester.pump();
    slow.release();
    await tester.pumpAndSettle();

    expect(slow.calls, 1);
    expect(await _decks(env), hasLength(1));
  });

  libraryTest('while Create writes, the dialog is held, Cancel is off and '
      'Create spins (M3 B2: every async confirm)', (tester, env) async {
    final slow = _SlowDecks(env.decks);
    await pumpLibraryScreen(
      tester,
      env,
      _host(),
      overrides: [
        createRootDeckUseCaseProvider.overrideWithValue(
          CreateRootDeckUseCase(slow),
        ),
      ],
    );
    await open(tester);
    await tester.enterText(find.byType(EditableText), 'Korean');
    await chooseEightBox(tester);
    await tester.tap(find.text(_en.deckCreateConfirm));
    await tester.pump();

    expect(tester.widget<MxDialog>(find.byType(MxDialog)).isHeld, isTrue);
    final cancel = find.ancestor(
      of: find.text(_en.commonCancel),
      matching: find.byType(MxButton),
    );
    expect(tester.widget<MxButton>(cancel.first).onPressed, isNull);
    final create = find.ancestor(
      of: find.text(_en.deckCreateConfirm),
      matching: find.byType(MxButton),
    );
    expect(tester.widget<MxButton>(create.first).isLoading, isTrue);

    slow.release();
    await tester.pumpAndSettle();
    expect(await _decks(env), hasLength(1));
  });

  libraryTest('a database failure keeps the dialog and says so plainly (RF4)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(),
      overrides: [
        createRootDeckUseCaseProvider.overrideWithValue(
          CreateRootDeckUseCase(_FailingDecks()),
        ),
      ],
    );
    await open(tester);
    await tester.enterText(find.byType(EditableText), 'Korean');
    await chooseEightBox(tester);
    await tester.tap(find.text(_en.deckCreateConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
    expect(find.text(_en.failureUnknown), findsOneWidget);
    expect(find.textContaining('sqlite'), findsNothing);
  });

  libraryTest('no scheduler is chosen up front; Create without one says so '
      'and writes nothing (BR-SRS-001, E3)', (tester, env) async {
    await pumpLibraryScreen(tester, env, _host());
    await open(tester);
    await tester.enterText(find.byType(EditableText), 'Korean');
    await tester.tap(find.text(_en.deckCreateConfirm));
    await tester.pumpAndSettle();

    expect(find.text(_en.deckSchedulerRequired), findsOneWidget);
    expect(find.byType(MxDialog), findsOneWidget);
    expect(await _decks(env), isEmpty);

    await chooseEightBox(tester);
    expect(find.text(_en.deckSchedulerRequired), findsNothing);
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('Cancel with nothing typed closes at once (A1)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _host());
    await open(tester);
    await tester.tap(find.text(_en.commonCancel));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsNothing);
  });

  libraryTest('Cancel after typing asks first: Keep editing keeps the name, '
      'Discard closes and writes nothing (A1)', (tester, env) async {
    await pumpLibraryScreen(tester, env, _host());
    await open(tester);
    await tester.enterText(find.byType(EditableText), 'Korean');
    await tester.tap(find.text(_en.commonCancel));
    await tester.pumpAndSettle();

    expect(find.text(_en.deckDiscardTitle), findsOneWidget);
    await tester.tap(find.text(_en.deckKeepEditing));
    await tester.pumpAndSettle();
    expect(find.text(_en.deckDiscardTitle), findsNothing);
    expect(find.text('Korean'), findsOneWidget);

    await tester.tap(find.text(_en.commonCancel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.deckDiscard));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsNothing);
    expect(await _decks(env), isEmpty);
  });

  libraryTest('the dialog meets the target guidelines', (tester, env) async {
    await pumpLibraryScreen(tester, env, _host());
    await open(tester);

    await expectAccessibleTargets(tester);
  });
}
