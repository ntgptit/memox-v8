import 'package:flutter/foundation.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';

/// The Trash's filter chips (UC-TRASH-001 A6).
enum TrashFilter {
  all,
  cards,
  decks;

  bool accepts(TrashEntry entry) => switch (this) {
    TrashFilter.all => true,
    TrashFilter.cards => entry is TrashCardEntry,
    TrashFilter.decks => entry is TrashDeckEntry,
  };
}

/// The two kinds a selection is locked to (BR-TRASH-011).
enum TrashKind {
  card,
  deck;

  static TrashKind of(TrashEntry entry) => switch (entry) {
    TrashCardEntry() => TrashKind.card,
    TrashDeckEntry() => TrashKind.deck,
  };
}

/// Screen 06's own state; the entries come from the store's stream.
@immutable
final class TrashState {
  const TrashState({
    this.filter = TrashFilter.all,
    this.isSelecting = false,
    this.selected = const {},
    this.blocked = const {},
  });

  final TrashFilter filter;

  /// "Select" or a long-press turned the rows into checkboxes.
  final bool isSelecting;

  /// The chosen batches, all of one kind.
  final Set<String> selected;

  /// The last purge's skipped batches, each with the batches still inside
  /// it (spec D6). They stay until the next command.
  final Map<String, Set<String>> blocked;

  /// The kind the selection is locked to, read from [entries]; null while
  /// nothing is chosen.
  TrashKind? kindIn(List<TrashEntry> entries) {
    for (final entry in entries) {
      if (selected.contains(entry.batchId)) return TrashKind.of(entry);
    }
    return null;
  }
}
