import 'package:memox/features/card/di/card_transfer_repository_provider.dart';
import 'package:memox/features/transfer/di/transfer_file_repository_provider.dart';
import 'package:memox/features/transfer/domain/usecases/build_export_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'build_export_use_case_provider.g.dart';

@riverpod
BuildExportUseCase buildExportUseCase(Ref ref) => BuildExportUseCase(
  ref.watch(cardTransferRepositoryProvider),
  ref.watch(transferFileRepositoryProvider),
);
