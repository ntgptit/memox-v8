import 'package:memox/features/card/domain/usecases/add_tag_to_cards_use_case.dart';
import 'package:memox/features/tags/di/tag_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'add_tag_to_cards_use_case_provider.g.dart';

@riverpod
AddTagToCardsUseCase addTagToCardsUseCase(Ref ref) =>
    AddTagToCardsUseCase(ref.watch(tagRepositoryProvider));
