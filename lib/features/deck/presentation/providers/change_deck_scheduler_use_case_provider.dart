import 'package:memox/features/deck/domain/usecases/change_deck_scheduler_use_case.dart';
import 'package:memox/features/srs/di/schedule_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'change_deck_scheduler_use_case_provider.g.dart';

@riverpod
ChangeDeckSchedulerUseCase changeDeckSchedulerUseCase(Ref ref) =>
    ChangeDeckSchedulerUseCase(ref.watch(scheduleRepositoryProvider));
