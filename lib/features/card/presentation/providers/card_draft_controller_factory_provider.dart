import 'package:memox/features/card/di/card_draft_repository_provider.dart';
import 'package:memox/features/card/presentation/controllers/card_draft_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_draft_controller_factory_provider.g.dart';

/// Builds the draft controller of one editor form; the form owns the result
/// and flushes it when it goes.
typedef CardDraftControllerFactory = CardDraftController Function(String key);

@riverpod
CardDraftControllerFactory cardDraftControllerFactory(Ref ref) {
  final repository = ref.watch(cardDraftRepositoryProvider);
  return (key) => CardDraftController(repository: repository, key: key);
}
