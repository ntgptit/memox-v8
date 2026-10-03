import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart' hide CardDraft;
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/card/data/repositories/card_transfer_repository_impl.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/repositories/card_transfer_repository.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/transfer/domain/usecases/commit_import_use_case.dart';
import 'package:memox/features/transfer/presentation/controllers/card_import_controller.dart';
import 'package:memox/features/transfer/presentation/providers/commit_import_use_case_provider.dart';
import 'package:memox/features/transfer/presentation/providers/import_file_picker_provider.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// The import wizard's steps over the real repositories and a fake picker
// (UC-TRANSFER-001, IT-NAV-012 step 4).
//
// What the import controller tests share: the database, the picker and the fakes.

DateTime importNow() => DateTime(2026, 9, 26);

ImportPickedFile pickedFile(String name, String text) =>
    (name: name, bytes: Uint8List.fromList(utf8.encode(text)));

Future<int> countCards(AppDatabase db) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM card').getSingle())
        .read<int>('n');

late AppDatabase db;
late DeckRepositoryImpl decks;
late DeckEntity root;
late DeckEntity leaf;
ImportPickedFile? picked;

void useImportFixture() {
  setUp(() async {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: importNow);
    root = await decks.root('r');
    leaf = await decks.sub(root.id, 'Nhà hàng');
    picked = pickedFile(
      'vocab.csv',
      'front,back,tags\nmenu,thực đơn,food\nbill,,\n',
    );
  });
  tearDown(() => db.close());
}

ProviderContainer container({
  CardTransferRepository Function(CardTransferRepository)? wrap,
}) {
  final cards = CardTransferRepositoryImpl(
    db,
    CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: importNow),
      TagRepositoryImpl(db, now: importNow),
      now: importNow,
    ),
  );
  final result = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      importFilePickerProvider.overrideWithValue(() async => picked),
      if (wrap != null)
        commitImportUseCaseProvider.overrideWithValue(
          CommitImportUseCase(wrap(cards)),
        ),
    ],
  );
  addTearDown(result.dispose);
  return result;
}

CardImportDraft draftOf(ProviderContainer c) =>
    c.read(cardImportControllerProvider(leaf.id)) as CardImportDraft;
