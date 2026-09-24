import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/usecases/delete_cards_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_cards_use_case_provider.g.dart';

@riverpod
DeleteCardsUseCase deleteCardsUseCase(Ref ref) =>
    DeleteCardsUseCase(ref.watch(cardRepositoryProvider));
