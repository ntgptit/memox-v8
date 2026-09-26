import 'package:flutter/services.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/starter_decks/data/datasources/template_asset_data_source.dart';
import 'package:memox/features/starter_decks/data/repositories/starter_library_repository_impl.dart';
import 'package:memox/features/starter_decks/domain/repositories/starter_library_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'starter_library_repository_provider.g.dart';

/// The library over the templates bundled with the app (starter decks spec
/// §5).
@riverpod
StarterLibraryRepository starterLibraryRepository(Ref ref) =>
    StarterLibraryRepositoryImpl(
      ref.watch(databaseProvider),
      ref.watch(deckRepositoryProvider),
      ref.watch(cardRepositoryProvider),
      templates: TemplateAssetDataSource(rootBundle).load,
    );
