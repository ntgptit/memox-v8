import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/usecases/create_card_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_card_use_case_provider.g.dart';

@riverpod
CreateCardUseCase createCardUseCase(Ref ref) =>
    CreateCardUseCase(ref.watch(cardRepositoryProvider));
