import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/usecases/watch_card_detail_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_card_detail_use_case_provider.g.dart';

@riverpod
WatchCardDetailUseCase watchCardDetailUseCase(Ref ref) =>
    WatchCardDetailUseCase(ref.watch(cardRepositoryProvider));
