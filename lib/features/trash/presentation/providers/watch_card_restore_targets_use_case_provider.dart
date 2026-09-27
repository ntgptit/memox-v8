import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/trash/domain/usecases/watch_card_restore_targets_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_card_restore_targets_use_case_provider.g.dart';

@riverpod
WatchCardRestoreTargetsUseCase watchCardRestoreTargetsUseCase(Ref ref) =>
    WatchCardRestoreTargetsUseCase(ref.watch(cardRepositoryProvider));
