import 'package:memox/features/account/di/user_role_repository_provider.dart';
import 'package:memox/features/account/domain/usecases/search_users_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_users_use_case_provider.g.dart';

@riverpod
SearchUsersUseCase searchUsersUseCase(Ref ref) =>
    SearchUsersUseCase(ref.watch(userRoleRepositoryProvider));
