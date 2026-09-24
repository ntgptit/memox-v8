import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/usecases/load_card_history_page_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'load_card_history_page_use_case_provider.g.dart';

@riverpod
LoadCardHistoryPageUseCase loadCardHistoryPageUseCase(Ref ref) =>
    LoadCardHistoryPageUseCase(ref.watch(cardRepositoryProvider));
