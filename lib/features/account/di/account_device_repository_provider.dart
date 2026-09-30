import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/account/data/repositories/account_device_repository_impl.dart';
import 'package:memox/features/account/domain/repositories/account_device_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_device_repository_provider.g.dart';

@riverpod
AccountDeviceRepository accountDeviceRepository(Ref ref) =>
    AccountDeviceRepositoryImpl(ref.watch(databaseProvider));
