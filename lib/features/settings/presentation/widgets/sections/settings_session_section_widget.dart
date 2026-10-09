import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/features/settings/presentation/states/settings_state.dart';
import 'package:memox/features/settings/presentation/widgets/overlays/new_card_order_sheet_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';

/// Screen 23a's Session section (settings hub spec §5.2): the card limit
/// by −/+, a hold or typing, beside its label, and the new-card order as a
/// value row that opens its sheet (owner 2026-10-07), each saved on change
/// (FE-A3 D1, D6).
class SettingsSessionSectionWidget extends ConsumerWidget {
  const SettingsSessionSectionWidget({super.key, required this.stored});

  /// The persisted defaults (BR-SETTINGS-001).
  final StudyOptions stored;

  /// Read in callbacks only, never while building.
  SettingsController _controller(WidgetRef ref) =>
      ref.read(settingsControllerProvider.notifier);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(settingsControllerProvider);
    final limit = state.cardLimitDraft ?? stored.cardLimit;
    return MxSection(
      title: l10n.settingsSessionSection,
      note: l10n.settingsSessionNote,
      children: [
        MxSettingsRow(
          // Short beside the stepper, which keeps the full name for screen
          // readers; the subtitle completes it (owner 2026-10-07).
          label: l10n.settingsCardLimitShort,
          subtitle: l10n.settingsCardLimitPerSession,
          icon: AppIcons.library,
          trailing: MxStepper(
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
            onValueSubmitted: (text) => _controller(ref).typeCardLimit(text),
            isInvalid: state.isCardLimitInvalid,
            isBusy: state.isBusy(SettingsSubmit.cardLimit),
          ),
          message: state.isCardLimitInvalid
              ? MxFieldMessage(
                  message: l10n.settingsCardLimitInvalid(
                    StudyOptions.minCardLimit,
                    StudyOptions.maxCardLimit,
                  ),
                )
              : null,
        ),
        MxSettingsRow(
          label: l10n.settingsNewCardOrder,
          subtitle: newCardOrderLabel(context, stored.newCardOrder),
          icon: AppIcons.shuffle,
          onTap: () async {
            final picked = await showNewCardOrderSheet(
              context,
              selected: stored.newCardOrder,
            );
            if (picked != null && context.mounted) {
              _controller(ref).chooseNewCardOrder(picked);
            }
          },
        ),
      ],
    );
  }
}
