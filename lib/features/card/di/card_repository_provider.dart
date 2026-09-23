import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/srs/di/schedule_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_repository_provider.g.dart';

@riverpod
CardRepository cardRepository(Ref ref) => CardRepositoryImpl(
  ref.watch(databaseProvider),
  ref.watch(scheduleRepositoryProvider),
);
