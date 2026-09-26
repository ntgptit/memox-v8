import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/domain/models/starter_template_model.dart';

/// A template as the Starter library lists it (kit screen 03, starter decks
/// spec §9): what its card shows, and whether it is already in the library.
final class StarterLibraryEntry {
  const StarterLibraryEntry({
    required this.templateId,
    required this.version,
    required this.title,
    required this.locale,
    required this.frontLanguage,
    required this.backLanguage,
    required this.contentSource,
    required this.suggestedScheduler,
    required this.cardCount,
    required this.subDeckCount,
    required this.isInLibrary,
  });

  /// The entry of [template]; [isInLibrary] when a copy of it at its version
  /// is outside the Trash (spec D7).
  factory StarterLibraryEntry.of(
    StarterTemplate template, {
    required bool isInLibrary,
  }) => StarterLibraryEntry(
    templateId: template.templateId,
    version: template.version,
    title: template.title,
    locale: template.locale,
    frontLanguage: template.frontLanguage,
    backLanguage: template.backLanguage,
    contentSource: template.contentSource,
    suggestedScheduler: template.suggestedScheduler,
    cardCount: template.cardCount,
    subDeckCount: template.subDeckCount,
    isInLibrary: isInLibrary,
  );

  final String templateId;
  final int version;
  final String title;
  final String locale;
  final String frontLanguage;
  final String backLanguage;
  final String contentSource;

  /// The scheduler the add sheet selects first (BR-STARTER-004).
  final SchedulerType suggestedScheduler;
  final int cardCount;
  final int subDeckCount;

  /// "In library" on the card, and "Add another copy" for its action
  /// (BR-STARTER-008).
  final bool isInLibrary;
}
