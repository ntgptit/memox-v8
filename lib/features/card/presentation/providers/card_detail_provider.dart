import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/presentation/providers/watch_card_detail_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_detail_provider.g.dart';

/// A card as its editor (and, in 4b, its detail) reads it, again on every
/// change; `Rejected(notFound)` once it is gone (BR-CARD-019).
@riverpod
Stream<Outcome<CardDetail, CardRejection>> cardDetail(Ref ref, String cardId) =>
    ref.watch(watchCardDetailUseCaseProvider)(cardId: cardId);
