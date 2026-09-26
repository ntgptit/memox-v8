import 'package:memox/features/transfer/data/repositories/export_share_repository_impl.dart';
import 'package:memox/features/transfer/domain/repositories/export_share_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'export_share_repository_provider.g.dart';

@riverpod
ExportShareRepository exportShareRepository(Ref ref) =>
    ExportShareRepositoryImpl();
