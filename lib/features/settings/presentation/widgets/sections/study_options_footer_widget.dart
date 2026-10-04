import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/settings/presentation/controllers/study_options_controller.dart';
import 'package:memox/features/settings/presentation/states/study_options_state.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';

/// Screen 15's Save (kit 15): enabled only for a valid change (D9); after
/// a failure it is Retry save, and the caption names what the deck still
/// uses (E4).
class StudyOptionsFooterWidget extends ConsumerWidget {
  const StudyOptionsFooterWidget({
    super.key,
    required this.deckId,
    required this.form,
  });

  final String deckId;
  final StudyOptionsForm form;

  /// Read in the callback only, never while building.
  void _save(WidgetRef ref) => unawaited(
    ref.read(studyOptionsControllerProvider(deckId).notifier).save(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final save = ref.watch(
      studyOptionsControllerProvider(deckId).select((s) => s.save),
    );
    final caption = switch (save) {
      _ when form.isCardLimitInvalid => l10n.studyOptionsFixLimit,
      _ => l10n.studyOptionsLocalOnly,
    };
    final (label, icon) = switch (save) {
      StudyOptionsSave.saving => (l10n.studyOptionsSaving, null),
      StudyOptionsSave.failed => (l10n.cardRetrySave, AppIcons.retry),
      StudyOptionsSave.idle => (l10n.cardSave, AppIcons.check),
    };
    return MxFooterBar(
      caption: caption,
      child: MxButton(
        label: label,
        icon: icon,
        isBlock: true,
        isLoading: save == StudyOptionsSave.saving,
        onPressed: form.canSave && save != StudyOptionsSave.saving
            ? () => _save(ref)
            : null,
      ),
    );
  }
}
