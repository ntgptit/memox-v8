import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/data/repositories/card_transfer_repository_impl.dart';
import 'package:memox/features/card/domain/repositories/card_transfer_repository.dart';
import 'package:memox/features/srs/di/schedule_repository_provider.dart';
import 'package:memox/features/tags/di/tag_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_transfer_repository_provider.g.dart';

@riverpod
CardTransferRepository cardTransferRepository(Ref ref) {
  final db = ref.watch(databaseProvider);
  return CardTransferRepositoryImpl(
    db,
    CardRepositoryImpl(
      db,
      ref.watch(scheduleRepositoryProvider),
      ref.watch(tagRepositoryProvider),
    ),
  );
}
