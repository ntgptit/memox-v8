import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';

/// The one implementation is `CardRepositoryImpl` (data layer). The contract
/// exists for ADR-010's reason: domain stays framework-free and tests
/// substitute a fake.
abstract interface class CardRepository {
  Future<Outcome<CardEntity, CardRejection>> createCard({
    required String deckId,
    required String front,
    required String back,
    String? example,
    String? hint,
    String? pronunciation,
    DateTime? now,
  });

  Future<Outcome<void, CardRejection>> deleteCard({required String cardId});
}
