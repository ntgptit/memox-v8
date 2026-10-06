import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/deck/data/datasources/deck_tree_data_source.dart';
import 'package:memox/features/deck/domain/repositories/deck_content_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deck_content_repository_provider.g.dart';

/// The deck feature's owner of a deck's content type, for the features
/// that add or remove a deck's children (DEV-215).
@riverpod
DeckContentRepository deckContentRepository(Ref ref) =>
    DeckTreeDataSource(ref.watch(databaseProvider));
