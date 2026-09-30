import 'package:memox/features/account/di/user_role_repository_provider.dart';
import 'package:memox/features/account/domain/usecases/set_user_role_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'set_user_role_use_case_provider.g.dart';

@riverpod
SetUserRoleUseCase setUserRoleUseCase(Ref ref) =>
    SetUserRoleUseCase(ref.watch(userRoleRepositoryProvider));
