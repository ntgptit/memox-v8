import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// A template just added to the library (UC-STARTER-001 step 8): what the
/// confirmation says and where Open goes (starter decks spec §9).
final class AddedStarterDeck {
  const AddedStarterDeck({
    required this.rootDeckId,
    required this.title,
    required this.schedulerType,
    required this.cardCount,
  });

  final String rootDeckId;
  final String title;
  final SchedulerType schedulerType;

  /// Every card of the copy, all of them new (UC-STARTER-001 step 9).
  final int cardCount;
}
