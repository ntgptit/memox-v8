import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/card/data/repositories/card_transfer_repository_impl.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/repositories/card_transfer_repository.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_transfer_repository_provider.g.dart';

@riverpod
CardTransferRepository cardTransferRepository(Ref ref) =>
    CardTransferRepositoryImpl(
      ref.watch(databaseProvider),
      ref.watch(cardRepositoryProvider),
      ref.watch(deckRepositoryProvider),
    );
