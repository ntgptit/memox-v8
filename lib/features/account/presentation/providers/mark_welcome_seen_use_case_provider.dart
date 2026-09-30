import 'package:memox/features/account/di/account_device_repository_provider.dart';
import 'package:memox/features/account/domain/usecases/mark_welcome_seen_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mark_welcome_seen_use_case_provider.g.dart';

@riverpod
MarkWelcomeSeenUseCase markWelcomeSeenUseCase(Ref ref) =>
    MarkWelcomeSeenUseCase(ref.watch(accountDeviceRepositoryProvider));
