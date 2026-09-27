import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/domain/models/starter_library_entry_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// Between the facts of a template's line (kit 03).
const String starterFactSeparator = ' · ';

/// The script subtag every romanisation carries, such as `ko-Latn`.
const String _latinScript = '-Latn';

/// The name of a language tag the build ships (FE-B4 spec D7); any other
/// tag shows as written.
String starterLanguageName(AppLocalizations l10n, String tag) {
  if (tag.endsWith(_latinScript)) return l10n.starterLanguageLatin;
  return switch (tag) {
    'en' => l10n.starterLanguageEnglish,
    'vi' => l10n.starterLanguageVietnamese,
    'ko' => l10n.starterLanguageKorean,
    _ => tag,
  };
}

String starterSchedulerName(AppLocalizations l10n, SchedulerType type) =>
    switch (type) {
      SchedulerType.sm2 => l10n.starterSchedulerSm2,
      SchedulerType.eightBox => l10n.starterSchedulerEightBox,
    };

String starterSchedulerDescription(AppLocalizations l10n, SchedulerType type) =>
    switch (type) {
      SchedulerType.sm2 => l10n.starterSm2Description,
      SchedulerType.eightBox => l10n.starterEightBoxDescription,
    };

/// "{front} · {back} · {n} cards · {m} sub-decks · {source}" (kit 03).
String starterEntryFacts(AppLocalizations l10n, StarterLibraryEntry entry) => [
  starterLanguageName(l10n, entry.frontLanguage),
  starterLanguageName(l10n, entry.backLanguage),
  l10n.starterCardCount(entry.cardCount),
  l10n.starterSubDeckCount(entry.subDeckCount),
  entry.contentSource,
].join(starterFactSeparator);
