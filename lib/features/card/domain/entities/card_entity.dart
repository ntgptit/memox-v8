import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';

final class CardEntity {
  const CardEntity({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.isFlagged,
    required this.example,
    required this.hint,
    required this.pronunciation,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String deckId;
  final String front;
  final String back;
  final bool isFlagged;
  final String? example;
  final String? hint;
  final String? pronunciation;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// BR-CARD-001: both faces carry text.
  static Outcome<void, CardRejection> checkContent({
    required String front,
    required String back,
  }) => front.trim().isEmpty || back.trim().isEmpty
      ? const Rejected(CardRejection.blankContent)
      : const Ok(null);
}
