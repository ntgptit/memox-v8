import 'package:memox/features/card/di/card_transfer_repository_provider.dart';
import 'package:memox/features/transfer/domain/usecases/count_export_cards_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'count_export_cards_use_case_provider.g.dart';

@riverpod
CountExportCardsUseCase countExportCardsUseCase(Ref ref) =>
    CountExportCardsUseCase(ref.watch(cardTransferRepositoryProvider));
