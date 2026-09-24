import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/usecases/edit_card_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'edit_card_use_case_provider.g.dart';

@riverpod
EditCardUseCase editCardUseCase(Ref ref) =>
    EditCardUseCase(ref.watch(cardRepositoryProvider));
