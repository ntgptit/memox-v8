import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/presentation/controllers/study_options_controller.dart';
import 'package:memox/features/settings/presentation/states/study_options_state.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

/// [order] as it reads inside a sentence.
String studyOptionsOrderName(AppLocalizations l10n, NewCardOrder order) =>
    switch (order) {
      NewCardOrder.created => l10n.studyOptionsOrderCreatedShort,
      NewCardOrder.random => l10n.studyOptionsOrderRandomShort,
    };

/// Screen 15's options: Use app defaults, then the card limit and the
/// new-card order, drawn as Settings draws them (ruling M3-E1), read-only
/// while the deck follows Settings (A1).
class StudyOptionsFormWidget extends ConsumerWidget {
  const StudyOptionsFormWidget({
    super.key,
    required this.deckId,
    required this.stored,
    required this.form,
    required this.rootName,
  });

  final String deckId;
  final EffectiveStudyOptions stored;
  final StudyOptionsForm form;

  /// The root deck whose options these are (BR-STUDY-056).
  final String rootName;

  /// Read in callbacks only, never while building.
  StudyOptionsController _controller(WidgetRef ref) =>
      ref.read(studyOptionsControllerProvider(deckId).notifier);

  static String _orderLabel(AppLocalizations l10n, NewCardOrder order) =>
      switch (order) {
        NewCardOrder.created => l10n.settingsOrderCreated,
        NewCardOrder.random => l10n.settingsOrderRandom,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final isSaving = ref.watch(
      studyOptionsControllerProvider(deckId).select((s) => s.isSaving),
    );
    final save = ref.watch(
      studyOptionsControllerProvider(deckId).select((s) => s.save),
    );
    // While Save runs the controls keep their look, as the kit draws it;
    // the controller ignores them until it ends (A4).
    final isEditable = !form.isUsingAppDefaults;
    final options = form.options;
    return MxScreenScroll(
      children: [
        MxNote(
          icon: AppIcons.library,
          text: l10n.studyOptionsBelongTo(rootName),
        ),
        // MxSection keeps its own 16 below; a note or banner above needs the
        // same (audit P1, pattern 4).
        const SizedBox(height: AppSpacing.gutter),
        if (stored.source == StudyOptionsSource.unreadableRootOverride) ...[
          MxInlineBanner(
            tone: MxBannerTone.warning,
            message: l10n.studyOptionsUnreadable,
          ),
          const SizedBox(height: AppSpacing.gutter),
        ],
        if (save == StudyOptionsSave.failed) ...[
          // A failed save leads the page, not a muted caption (critique
          // 2026-09-30 part 3d-1); the footer keeps Retry save.
          MxInlineBanner(
            tone: MxBannerTone.danger,
            title: l10n.studyOptionsNotSavedTitle,
            message: l10n.studyOptionsSaveFailed(
              stored.options.cardLimit,
              studyOptionsOrderName(l10n, stored.options.newCardOrder),
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
        ],
        MxSection(
          children: [
            MxSettingsRow(
              label: l10n.studyOptionsUseAppDefaults,
              icon: AppIcons.studyOptions,
              subtitle: form.isUsingAppDefaults
                  ? l10n.studyOptionsFollowing(
                      options.cardLimit,
                      studyOptionsOrderName(l10n, options.newCardOrder),
                    )
                  : l10n.studyOptionsOwn,
              trailing: MxToggle(
                isOn: form.isUsingAppDefaults,
                semanticLabel: l10n.studyOptionsUseAppDefaults,
                onChanged: (isOn) =>
                    _controller(ref).useAppDefaults(isOn: isOn),
              ),
            ),
          ],
        ),
        MxSection(
          title: form.isUsingAppDefaults
              ? l10n.studyOptionsAppDefaultsHeader
              : l10n.studyOptionsThisDeck,
          children: [
            MxSettingsRow(
              label: l10n.settingsCardLimit,
              icon: AppIcons.library,
              subtitle: l10n.studyOptionsCardLimitRange(
                StudyOptions.maxCardLimit,
              ),
              // Following the defaults, the value reads at full contrast
              // (critique 2026-09-30); the controls come with an override.
              trailing: isEditable
                  ? null
                  : Text(
                      l10n.studyCount(options.cardLimit),
                      style: styles.settingsLabel,
                    ),
              wideControl: !isEditable
                  ? null
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppSpacing.micro,
                      children: [
                        MxStepper(
                          value: options.cardLimit,
                          decrementLabel: l10n.settingsFewerCards,
                          incrementLabel: l10n.settingsMoreCards,
                          valueLabel: l10n.settingsCardLimit,
                          editHint: l10n.commonEdit,
                          isEnabled: isEditable,
                          isBusy: isSaving,
                          isInvalid: form.isCardLimitInvalid,
                          onDecrement:
                              options.cardLimit > StudyOptions.minCardLimit
                              ? () => _controller(ref).stepCardLimit(-1)
                              : null,
                          onIncrement:
                              options.cardLimit < StudyOptions.maxCardLimit
                              ? () => _controller(ref).stepCardLimit(1)
                              : null,
                          onValueSubmitted: (text) =>
                              _controller(ref).typeCardLimit(text),
                        ),
                        if (form.isCardLimitInvalid)
                          MxFieldMessage(
                            message: l10n.settingsCardLimitInvalid(
                              StudyOptions.minCardLimit,
                              StudyOptions.maxCardLimit,
                            ),
                          ),
                      ],
                    ),
            ),
            MxSettingsRow(
              label: l10n.settingsNewCardOrder,
              subtitle: l10n.settingsNewCardOrderHint,
              icon: AppIcons.shuffle,
              trailing: isEditable
                  ? null
                  : Text(
                      _orderLabel(l10n, options.newCardOrder),
                      style: styles.settingsLabel,
                    ),
              wideControl: !isEditable
                  ? null
                  : MxSegmentedTray<NewCardOrder>(
                      segments: [
                        MxSegment(
                          value: NewCardOrder.created,
                          label: l10n.settingsOrderCreated,
                        ),
                        MxSegment(
                          value: NewCardOrder.random,
                          label: l10n.settingsOrderRandom,
                        ),
                      ],
                      selected: options.newCardOrder,
                      onSelected: isEditable
                          ? (order) =>
                                _controller(ref).chooseNewCardOrder(order)
                          : null,
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
