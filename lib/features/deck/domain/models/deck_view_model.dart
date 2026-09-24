import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_create_option_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// An open deck: what its screen and its Create menu need.
final class DeckView {
  const DeckView({
    required this.deck,
    required this.schedulerType,
    required this.isSchedulerLocked,
    required this.breadcrumb,
  });

  final DeckEntity deck;

  /// The scheduler of the deck's root (BR-DECK-024).
  final SchedulerType schedulerType;

  /// The root has an answer, so its scheduler cannot change (BR-SRS-003).
  final bool isSchedulerLocked;

  /// The decks from the root down to the parent; empty for a root.
  final List<DeckPathEntry> breadcrumb;

  Set<DeckCreateOption> get createOptions => deck.createOptions;
}
