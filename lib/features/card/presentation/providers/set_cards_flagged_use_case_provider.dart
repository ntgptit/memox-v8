import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/usecases/set_cards_flagged_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'set_cards_flagged_use_case_provider.g.dart';

@riverpod
SetCardsFlaggedUseCase setCardsFlaggedUseCase(Ref ref) =>
    SetCardsFlaggedUseCase(ref.watch(cardRepositoryProvider));
