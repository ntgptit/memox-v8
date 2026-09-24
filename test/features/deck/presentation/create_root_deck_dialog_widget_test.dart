import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/deck/domain/usecases/create_root_deck_use_case.dart';
import 'package:memox/features/deck/presentation/providers/create_root_deck_use_case_provider.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/create_root_deck_dialog_widget.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

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
    DateTime? now,
  }) async {
    calls++;
    await _gate.future;
    return _real.createRootDeck(
      name: name,
      schedulerType: schedulerType,
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

  libraryTest('a blank name is refused under the field; nothing is written', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _host());
    await open(tester);
    await tester.tap(find.text(_en.deckCreateConfirm));
    await tester.pumpAndSettle();

    expect(find.text(_en.deckRejectionBlankName), findsOneWidget);
    expect(find.byType(MxDialog), findsOneWidget);
    expect(await _decks(env), isEmpty);
  });

  libraryTest('a name longer than 200 characters is refused', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _host());
    await open(tester);
    await tester.enterText(find.byType(EditableText), 'a' * 201);
    await tester.tap(find.text(_en.deckCreateConfirm));
    await tester.pumpAndSettle();

    expect(find.text(_en.deckRejectionNameTooLong), findsOneWidget);
  });

  libraryTest('a name and SM-2 create a root deck and close the dialog', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _host());
    await open(tester);
    await tester.enterText(find.byType(EditableText), '  Korean  ');
    await tester.tap(find.text(_en.deckSchedulerSm2));
    await tester.pump();
    await tester.tap(find.text(_en.deckCreateConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsNothing);
    expect(await _decks(env), [('Korean', 'sm2')]);
  });

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
    await tester.tap(find.text(_en.deckCreateConfirm));
    await tester.pump();
    await tester.tap(find.text(_en.deckCreateConfirm), warnIfMissed: false);
    await tester.pump();
    slow.release();
    await tester.pumpAndSettle();

    expect(slow.calls, 1);
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
    await tester.tap(find.text(_en.deckCreateConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
    expect(find.text(_en.failureUnknown), findsOneWidget);
    expect(find.textContaining('sqlite'), findsNothing);
  });

  libraryTest('the dialog meets the target guidelines', (tester, env) async {
    await pumpLibraryScreen(tester, env, _host());
    await open(tester);

    await expectAccessibleTargets(tester);
  });
}
