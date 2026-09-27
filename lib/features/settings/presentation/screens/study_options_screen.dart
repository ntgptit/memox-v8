import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/presentation/controllers/study_options_controller.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/providers/study_options_provider.dart';
import 'package:memox/features/settings/presentation/states/study_options_state.dart';
import 'package:memox/features/settings/presentation/widgets/sections/study_options_footer_widget.dart';
import 'package:memox/features/settings/presentation/widgets/sections/study_options_form_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 15, a root deck's study options, open on any deck of its tree
/// (UC-SETTINGS-001 A1, BR-STUDY-056): its own options or the app defaults,
/// saved by Save for sessions started afterwards (BR-SETTINGS-004).
class StudyOptionsScreen extends ConsumerWidget {
  const StudyOptionsScreen({
    super.key,
    required this.deckId,
    required this.breadcrumb,
  });

  final String deckId;

  /// The deck's path from the Library, ending at "Study options"; composed
  /// by `app/` from the deck feature, which settings may not read (C6).
  final Widget breadcrumb;

  static const int _skeletonRows = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref.listen(
      studyOptionsControllerProvider(deckId).select((s) => s.timesSaved),
      (before, after) {
        if (after > (before ?? 0)) {
          showMxSnackbar(context, message: l10n.studyOptionsSaved);
        }
      },
    );
    final draft = ref.watch(studyOptionsControllerProvider(deckId));
    final appDefaults = ref.watch(appSettingsProvider).value?.studyDefaults;
    final options = ref.watch(studyOptionsProvider(deckId));
    final loaded = switch ((options, appDefaults)) {
      (AsyncData(value: Ok(:final value)), final defaults?) => (
        value,
        StudyOptionsForm.of(value, draft, appDefaults: defaults),
      ),
      _ => null,
    };
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.deckStudyOptions,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          breadcrumb,
          Expanded(
            child: switch (options) {
              _ when loaded != null => StudyOptionsFormWidget(
                deckId: deckId,
                stored: loaded.$1,
                form: loaded.$2,
                rootName: loaded.$1.rootDeckName,
              ),
              AsyncData(value: Rejected()) => _gone(context),
              AsyncError() => MxScreenScroll(
                children: [
                  MxErrorState(
                    title: l10n.settingsLoadErrorTitle,
                    body: l10n.libraryLoadErrorBody,
                    retryLabel: l10n.commonRetry,
                    onRetry: () => ref.invalidate(studyOptionsProvider(deckId)),
                  ),
                ],
              ),
              _ => MxScreenScroll(
                children: [
                  MxSkeletonList(
                    semanticLabel: l10n.commonLoading,
                    rows: _skeletonRows,
                  ),
                ],
              ),
            },
          ),
        ],
      ),
      footer: switch (loaded) {
        (final EffectiveStudyOptions stored, final StudyOptionsForm form) =>
          StudyOptionsFooterWidget(deckId: deckId, stored: stored, form: form),
        null => null,
      },
    );
  }

  /// The deck went to the Trash or no longer exists (spec §6).
  Widget _gone(BuildContext context) {
    final l10n = context.l10n;
    return MxScreenScroll(
      children: [
        MxEmptyState(
          icon: AppIcons.searchOff,
          title: l10n.deckGoneTitle,
          body: l10n.deckGoneBody,
          actionLabel: l10n.commonBack,
          onAction: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ],
    );
  }
}
