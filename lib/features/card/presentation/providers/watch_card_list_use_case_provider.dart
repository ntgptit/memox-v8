import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/usecases/watch_card_list_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_card_list_use_case_provider.g.dart';

@riverpod
WatchCardListUseCase watchCardListUseCase(Ref ref) => WatchCardListUseCase(
  ref.watch(cardRepositoryProvider),
  ref.watch(dayClockProvider),
);
