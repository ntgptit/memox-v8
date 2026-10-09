import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/speech/di/speech_providers.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/features/settings/presentation/widgets/overlays/speech_language_sheet_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

/// Screen 23a's Speech section (settings hub spec §5.2; study speech spec
/// §6): the read-aloud switch and the default speech language, each saved
/// on change (BR-SETTINGS-009, BR-SETTINGS-010).
class SettingsSpeechSectionWidget extends ConsumerWidget {
  const SettingsSpeechSectionWidget({
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
    return MxSection(
      title: l10n.settingsSpeechSection,
      note: l10n.settingsSpeechNote,
      children: [
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
        // The value first in the subtitle and a chevron, as the Theme and
        // Language rows do: a trailing value hides the chevron and reads as
        // a label (critique 2026-10-07).
        MxSettingsRow(
          label: l10n.settingsSpeechLanguage,
          subtitle: l10n.settingsSpeechLanguageValue(
            l10n.speechLanguageName(stored.speechLanguage.name),
          ),
          icon: AppIcons.voice,
          onTap: () async {
            final picked = await showSpeechLanguageSheet(
              context,
              selected: stored.speechLanguage,
              speech: ref.read(speechSynthesizerProvider),
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
