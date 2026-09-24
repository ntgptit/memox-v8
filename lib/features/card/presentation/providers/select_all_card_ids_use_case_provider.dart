import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/usecases/select_all_card_ids_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'select_all_card_ids_use_case_provider.g.dart';

@riverpod
SelectAllCardIdsUseCase selectAllCardIdsUseCase(Ref ref) =>
    SelectAllCardIdsUseCase(
      ref.watch(cardRepositoryProvider),
      ref.watch(dayClockProvider),
    );
