import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/usecases/move_cards_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'move_cards_use_case_provider.g.dart';

@riverpod
MoveCardsUseCase moveCardsUseCase(Ref ref) =>
    MoveCardsUseCase(ref.watch(cardRepositoryProvider));
