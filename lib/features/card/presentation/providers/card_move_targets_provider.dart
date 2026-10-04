import 'package:memox/features/card/domain/models/card_move_target_model.dart';
import 'package:memox/features/card/presentation/providers/watch_card_move_targets_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_move_targets_provider.g.dart';

/// The decks cards of [sourceDeckId] may move to (UC-CARD-001 A5).
@riverpod
Stream<List<CardMoveTarget>> cardMoveTargets(Ref ref, String sourceDeckId) =>
    ref.watch(watchCardMoveTargetsUseCaseProvider)(sourceDeckId: sourceDeckId);
