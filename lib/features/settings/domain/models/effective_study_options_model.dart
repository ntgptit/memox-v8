import 'package:memox/features/settings/domain/models/study_options_model.dart';

/// Where the options in force for a deck come from (BR-STUDY-056).
enum StudyOptionsSource {
  /// The root has no override: the app-wide defaults apply.
  appDefaults,

  /// The root's override applies.
  rootOverride,

  /// The root holds an override that cannot be read: the app-wide defaults
  /// apply, and the stored override stays as it is (IT-STUDY-013).
  unreadableRootOverride,
}

/// The study options in force for a deck: its root's override, or the
/// app-wide defaults. A sub-deck has no options of its own (BR-STUDY-056).
final class EffectiveStudyOptions {
  const EffectiveStudyOptions({
    required this.rootDeckId,
    required this.options,
    required this.source,
  });

  final String rootDeckId;
  final StudyOptions options;
  final StudyOptionsSource source;

  /// Whether `Use app defaults` has an override to clear
  /// (UC-SETTINGS-001 A1).
  bool get hasRootOverride => source != StudyOptionsSource.appDefaults;
}
