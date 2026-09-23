import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deck_repository_provider.g.dart';

@riverpod
DeckRepository deckRepository(Ref ref) =>
    DeckRepositoryImpl(ref.watch(databaseProvider));
