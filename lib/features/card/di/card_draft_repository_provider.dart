import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/card/data/repositories/card_draft_repository_impl.dart';
import 'package:memox/features/card/domain/repositories/card_draft_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_draft_repository_provider.g.dart';

@riverpod
CardDraftRepository cardDraftRepository(Ref ref) =>
    CardDraftRepositoryImpl(ref.watch(databaseProvider));
