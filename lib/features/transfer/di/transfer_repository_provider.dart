import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/transfer/data/repositories/transfer_repository_impl.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transfer_repository_provider.g.dart';

@riverpod
TransferRepository transferRepository(Ref ref) => TransferRepositoryImpl(
  ref.watch(databaseProvider),
  ref.watch(cardRepositoryProvider),
);
