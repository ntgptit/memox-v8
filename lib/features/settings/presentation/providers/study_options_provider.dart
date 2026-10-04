import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/presentation/providers/watch_study_options_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_options_provider.g.dart';

/// The options in force for [deckId]: its root's override or the app
/// defaults, again whenever either changes (BR-STUDY-056); `deckNotFound`
/// once the deck is gone or in the Trash.
@riverpod
Stream<Outcome<EffectiveStudyOptions, SettingsRejection>> studyOptions(
  Ref ref,
  String deckId,
) => ref.watch(watchStudyOptionsUseCaseProvider)(deckId: deckId);
