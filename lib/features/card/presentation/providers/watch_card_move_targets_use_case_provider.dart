import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/usecases/watch_card_move_targets_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_card_move_targets_use_case_provider.g.dart';

@riverpod
WatchCardMoveTargetsUseCase watchCardMoveTargetsUseCase(Ref ref) =>
    WatchCardMoveTargetsUseCase(ref.watch(cardRepositoryProvider));
