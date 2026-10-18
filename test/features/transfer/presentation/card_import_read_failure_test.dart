import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/models/card_import_target_model.dart';
import 'package:memox/features/card/domain/repositories/card_transfer_repository.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/transfer/domain/usecases/preview_import_use_case.dart';
import 'package:memox/features/transfer/presentation/controllers/card_import_controller.dart';
import 'package:memox/features/transfer/presentation/providers/import_file_picker_provider.dart';
import 'package:memox/features/transfer/presentation/providers/preview_import_use_case_provider.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// A step's read that fails never leaves the wizard busy, where Back waits
// (UC-TRANSFER-001 step 5; closing review 2026-10-17).

DateTime _now() => DateTime(2026, 9, 26);

/// Fails the deck read the preview starts with, the way a locked database
/// does, or with [bug].
final class _BrokenTarget implements CardTransferRepository {
  _BrokenTarget({this.bug});

  final Object? bug;

  @override
  Future<CardImportTarget?> importTarget(String deckId) async {
    if (bug case final bug?) throw bug;
    throw const DatabaseLockedFailure(cause: 'locked');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late DeckEntity leaf;

  setUp(() async {
    db = openTestDatabase();
    final decks = DeckRepositoryImpl(db, now: _now);
    final root = await decks.root('r');
    leaf = await decks.sub(root.id, 'Nhà hàng');
  });
  tearDown(() => db.close());

  ProviderContainer container(CardTransferRepository cards) {
    final result = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        importFilePickerProvider.overrideWithValue(
          () async => (
            name: 'vocab.csv',
            bytes: Uint8List.fromList(
              utf8.encode('front,back\nmenu,thực đơn\n'),
            ),
          ),
        ),
        previewImportUseCaseProvider.overrideWithValue(
          PreviewImportUseCase(cards),
        ),
      ],
    );
    addTearDown(result.dispose);
    return result;
  }

  CardImportDraft draftOf(ProviderContainer c) =>
      c.read(cardImportControllerProvider(leaf.id)) as CardImportDraft;

  test('a failed preview leaves busy, passes the Failure on, and Back still '
      'steps back', () async {
    final c = container(_BrokenTarget());
    final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
    c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
    await wizard.chooseFile();
    await wizard.readSource();

    await expectLater(
      wizard.previewRows(defaultDeckName: 'Uncategorized'),
      throwsA(isA<DatabaseLockedFailure>()),
    );
    expect(draftOf(c).isBusy, isFalse);
    expect(draftOf(c).step, CardImportStep.columns);
    expect(wizard.stepBack(), isTrue);
    expect(draftOf(c).step, CardImportStep.source);
  });

  test('a bug in the preview is reported and leaves busy', () async {
    final c = container(_BrokenTarget(bug: StateError('a bug')));
    final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
    c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
    await wizard.chooseFile();
    await wizard.readSource();

    final reported = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = reported.add;
    addTearDown(() => FlutterError.onError = previous);
    await wizard.previewRows(defaultDeckName: 'Uncategorized');

    expect(draftOf(c).isBusy, isFalse);
    expect(reported.single.exception, isA<StateError>());
  });
}
