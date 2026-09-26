import 'package:memox/features/transfer/data/repositories/transfer_file_repository_impl.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_file_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transfer_file_repository_provider.g.dart';

@riverpod
TransferFileRepository transferFileRepository(Ref ref) =>
    const TransferFileRepositoryImpl();
