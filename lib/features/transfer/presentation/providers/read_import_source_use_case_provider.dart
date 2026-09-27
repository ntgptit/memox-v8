import 'package:memox/features/transfer/di/transfer_file_repository_provider.dart';
import 'package:memox/features/transfer/domain/usecases/read_import_source_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'read_import_source_use_case_provider.g.dart';

@riverpod
ReadImportSourceUseCase readImportSourceUseCase(Ref ref) =>
    ReadImportSourceUseCase(ref.watch(transferFileRepositoryProvider));
