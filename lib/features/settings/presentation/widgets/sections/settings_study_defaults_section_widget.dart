import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/features/settings/presentation/states/settings_state.dart';
import 'package:memox/features/settings/presentation/widgets/overlays/speech_language_sheet_widget.dart';
import 'package:memox/features/settings/presentation/widgets/support/speech_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

/// Screen 23's Study defaults (UC-SETTINGS-001 step 2): the card limit by
/// −/+, a hold or typing, the new-card order, the read-aloud switch and the
/// speech language, each saved on change (FE-A3 D1, D6; study speech spec
/// §6).
class SettingsStudyDefaultsSectionWidget extends ConsumerWidget {
  const SettingsStudyDefaultsSectionWidget({
    super.key,
    required this.stored,
    required this.isSpeechAutoPlay,
  });

  /// The persisted defaults (BR-SETTINGS-001).
  final StudyOptions stored;

  /// The persisted read-aloud switch (BR-SETTINGS-010).
  final bool isSpeechAutoPlay;

  /// Read in callbacks only, never while building.
  SettingsController _controller(WidgetRef ref) =>
      ref.read(settingsControllerProvider.notifier);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(settingsControllerProvider);
    final limit = state.cardLimitDraft ?? stored.cardLimit;
    return MxSection(
      title: l10n.settingsStudyDefaults,
      note: l10n.settingsStudyDefaultsNote,
      children: [
        MxSettingsRow(
          label: l10n.settingsCardLimit,
          subtitle: l10n.settingsCardLimitRange(
            StudyOptions.maxCardLimit,
            StudyOptions.defaultCardLimit,
          ),
          icon: AppIcons.library,
          wideControl: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.micro,
            children: [
              MxStepper(
                value: limit,
                decrementLabel: l10n.settingsFewerCards,
                incrementLabel: l10n.settingsMoreCards,
                valueLabel: l10n.settingsCardLimit,
                editHint: l10n.commonEdit,
                onDecrement: limit > StudyOptions.minCardLimit
                    ? () => _controller(ref).stepCardLimit(-1)
                    : null,
                onIncrement: limit < StudyOptions.maxCardLimit
                    ? () => _controller(ref).stepCardLimit(1)
                    : null,
                onValueSubmitted: (text) =>
                    _controller(ref).typeCardLimit(text),
                isInvalid: state.isCardLimitInvalid,
                isBusy: state.isBusy(SettingsSubmit.cardLimit),
              ),
              if (state.isCardLimitInvalid)
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
          wideControl: MxSegmentedTray<NewCardOrder>(
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
            selected: stored.newCardOrder,
            onSelected: (order) => _controller(ref).chooseNewCardOrder(order),
          ),
        ),
        MxSettingsRow(
          label: l10n.settingsSpeechAutoPlay,
          subtitle: l10n.settingsSpeechAutoPlayHint,
          icon: AppIcons.speak,
          trailing: MxToggle(
            isOn: isSpeechAutoPlay,
            semanticLabel: l10n.settingsSpeechAutoPlay,
            onChanged: (isOn) => _controller(ref).setSpeechAutoPlay(isOn: isOn),
          ),
        ),
        MxSettingsRow(
          label: l10n.settingsSpeechLanguage,
          subtitle: l10n.settingsSpeechLanguageHint,
          icon: AppIcons.speak,
          trailing: Text(
            speechLanguageName(l10n, stored.speechLanguage),
            style: context.textStyles.settingsLabel,
          ),
          onTap: () async {
            final picked = await showSpeechLanguageSheet(
              context,
              selected: stored.speechLanguage,
            );
            if (picked != null && context.mounted) {
              _controller(ref).chooseSpeechLanguage(picked);
            }
          },
        ),
      ],
    );
  }
}
