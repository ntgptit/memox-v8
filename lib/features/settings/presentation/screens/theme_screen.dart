import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/states/settings_state.dart';
import 'package:memox/features/settings/presentation/widgets/items/theme_choice_card_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 25, the theme (UC-SETTINGS-001 step 4): a tap saves the choice
/// and the whole app follows at once, this page included
/// (BR-SETTINGS-005, FE-A3 D2, D7).
class ThemeScreen extends ConsumerWidget {
  const ThemeScreen({super.key});

  static const int _skeletonRows = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref.listen(settingsControllerProvider.select((state) => state.notice), (
      _,
      notice,
    ) {
      if (notice is! SettingsSaveFailed) return;
      if (notice.kind != SettingsSubmit.theme) return;
      showMxSnackbar(
        context,
        message: l10n.settingsThemeSaveFailed,
        actionLabel: l10n.commonRetry,
        onAction: () => unawaited(
          ref
              .read(settingsControllerProvider.notifier)
              .retry(SettingsSubmit.theme),
        ),
      );
    });
    final settings = ref.watch(appSettingsProvider);
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.settingsTheme,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: switch (settings) {
        AsyncData(:final value) => MxScreenScroll(
          children: [
            const SizedBox(height: AppSpacing.control),
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  for (final theme in ThemeChoice.values)
                    ThemeChoiceCardWidget(
                      theme: theme,
                      isSelected: value.theme == theme,
                      onSelected: () => ref
                          .read(settingsControllerProvider.notifier)
                          .chooseTheme(theme),
                    ),
                ];
                final share =
                    (constraints.maxWidth - AppSpacing.control * 2) /
                    cards.length;
                // Large text or long words: one card per line, whole words.
                if (share < ThemeChoiceCardWidget.minWidth(context)) {
                  return Column(spacing: AppSpacing.control, children: cards);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.control,
                  children: [for (final card in cards) Expanded(child: card)],
                );
              },
            ),
            const SizedBox(height: AppSpacing.gutter),
            Text(
              l10n.settingsAppliesAtOnce,
              style: context.textStyles.noteText,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        AsyncError() => MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.settingsLoadErrorTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(appSettingsProvider),
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
    );
  }
}
