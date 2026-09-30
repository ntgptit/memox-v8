import 'package:memox/features/account/di/account_device_repository_provider.dart';
import 'package:memox/features/account/domain/usecases/count_local_library_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'count_local_library_use_case_provider.g.dart';

@riverpod
CountLocalLibraryUseCase countLocalLibraryUseCase(Ref ref) =>
    CountLocalLibraryUseCase(ref.watch(accountDeviceRepositoryProvider));
