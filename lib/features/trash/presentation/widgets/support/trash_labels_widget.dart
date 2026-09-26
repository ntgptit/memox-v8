import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// Between two decks of a path. Each feature has its own join (ruling
/// P3-L8).
const String trashPathSeparator = ' › ';

/// Between a card's front and back in its name (kit 06).
const String trashSidesSeparator = ' · ';

/// Under this much time left, the row says so in the warning ink (kit 06).
const Duration trashExpiringSoon = Duration(days: 3);

/// The entry as the person knows it: a deck's name, a card's two sides.
String trashEntryName(TrashEntry entry) => switch (entry) {
  TrashDeckEntry(:final name) => name,
  TrashCardEntry(:final front, :final back) =>
    '$front$trashSidesSeparator$back',
};

/// The decks the item was in, root first; a root was at the top level.
String trashOrigin(AppLocalizations l10n, TrashEntry entry) =>
    entry.origin.isEmpty
    ? l10n.trashTopLevel
    : entry.origin.map((deck) => deck.name).join(trashPathSeparator);

/// The deck the item was in, the origin's last; the top level for a root.
String trashParent(AppLocalizations l10n, TrashEntry entry) =>
    entry.origin.isEmpty ? l10n.trashTopLevel : entry.origin.last.name;

/// How long ago the entry was deleted, for "deleted {ago}".
String trashDeletedAgo(
  AppLocalizations l10n,
  DateTime deletedAt,
  DateTime now,
) {
  final elapsed = now.difference(deletedAt);
  if (elapsed.inHours < 1) return l10n.trashDeletedMinutes(elapsed.inMinutes);
  if (elapsed.inDays < 1) return l10n.trashDeletedHours(elapsed.inHours);
  if (elapsed.inDays == 1) return l10n.trashDeletedYesterday;
  return l10n.trashDeletedDays(elapsed.inDays);
}

/// The time until the auto-purge takes the entry (BR-TRASH-009): whole days
/// rounded up, then hours under a day, never less than one.
String trashTimeLeft(AppLocalizations l10n, TrashEntry entry, DateTime now) {
  final left = entry.expiresAt.difference(now);
  if (left >= _day) return l10n.trashDaysLeft(_roundedUp(left, _day));
  final hours = _roundedUp(left, _hour);
  return l10n.trashHoursLeft(hours < 1 ? 1 : hours);
}

const Duration _day = Duration(days: 1);
const Duration _hour = Duration(hours: 1);

bool isTrashExpiringSoon(TrashEntry entry, DateTime now) =>
    entry.expiresAt.difference(now) < trashExpiringSoon;

int _roundedUp(Duration value, Duration unit) =>
    (value.inMicroseconds + unit.inMicroseconds - 1) ~/ unit.inMicroseconds;
