import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/account/presentation/controllers/sign_in_controller.dart';
import 'package:memox/features/account/presentation/providers/can_link_provider.dart';
import 'package:memox/features/account/presentation/providers/welcome_due_provider.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/features/account/presentation/widgets/overlays/merge_choice_sheet_widget.dart';
import 'package:memox/features/account/presentation/widgets/support/account_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 29 (account UI spec U1, §5.1, §6): the first launch invites an
/// account. The name, the promise and three benefits sit on top; the three
/// ways on sit in the thumb zone, Google the one fill. Every exit answers
/// Welcome for good. There is no back: Back leaves the app, as on any
/// root.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key, required this.onDone, required this.onEmail});

  /// Goes on to where the launch was headed.
  final VoidCallback onDone;

  /// Opens screen 30 for an email code (plan ruling 4).
  final VoidCallback onEmail;

  static const _link = SignInPurpose.link;

  /// The router lets go of Welcome first, so the navigation that follows
  /// is not sent back to it.
  void _leave(WidgetRef ref, VoidCallback next) {
    unawaited(ref.read(welcomeDueProvider.notifier).dismiss());
    next();
  }

  Future<void> _google(BuildContext context, WidgetRef ref) async {
    final outcome = await ref
        .read(signInControllerProvider(_link).notifier)
        .continueWithGoogle();
    if (!context.mounted) return;
    switch (outcome) {
      case SignInOutcome.signedIn:
        saySignedIn(context, attachedAccount(ref));
        _leave(ref, onDone);
      case SignInOutcome.identityTaken:
        final isSwitching = await startLinkSwitch(context, ref);
        if (isSwitching && context.mounted) _leave(ref, onDone);
      case SignInOutcome.failed:
        final problem = ref.read(signInControllerProvider(_link)).problem;
        if (problem == null) return;
        showMxSnackbar(
          context,
          message: signInProblemText(context.l10n, problem),
        );
      case SignInOutcome.codeSent || SignInOutcome.none:
        return;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canLink = ref.watch(canLinkProvider);
    final isRunning = ref.watch(signInControllerProvider(_link)).isRunning;
    final canSignIn = canLink && !isRunning;
    return MxAppShell(
      body: SafeArea(
        bottom: false,
        child: MxScreenScroll(
          children: [
            const SizedBox(height: AppSpacing.major),
            // Plan U5: a tile until MemoX has its own icon (UI-base debt).
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: MxIconTile(
                icon: AppIcons.library,
                size: MxIconTileSize.large,
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            Semantics(
              header: true,
              child: Text(l10n.appTitle, style: context.textStyles.screenTitle),
            ),
            const SizedBox(height: AppSpacing.control),
            Text(l10n.welcomeLead, style: context.textStyles.emptyBody),
            const SizedBox(height: AppSpacing.section),
            MxSection(
              children: [
                MxSettingsRow(
                  label: l10n.welcomeBenefitReinstall,
                  icon: AppIcons.safe,
                ),
                MxSettingsRow(
                  label: l10n.welcomeBenefitPhones,
                  icon: AppIcons.devices,
                ),
                MxSettingsRow(
                  label: l10n.welcomeBenefitOffline,
                  icon: AppIcons.offline,
                ),
              ],
            ),
            if (!canLink) MxNote(text: l10n.accountOfflineNote),
          ],
        ),
      ),
      footer: MxFooterBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.grouped,
          children: [
            MxButton(
              label: l10n.accountContinueGoogle,
              mark: googleMark,
              isBlock: true,
              isLoading: isRunning,
              onPressed: canSignIn
                  ? () => unawaited(_google(context, ref))
                  : null,
            ),
            MxButton(
              label: l10n.accountContinueEmail,
              tone: MxButtonTone.outline,
              isBlock: true,
              onPressed: canSignIn ? () => _leave(ref, onEmail) : null,
            ),
            MxButton(
              label: l10n.accountContinueWithout,
              tone: MxButtonTone.text,
              isBlock: true,
              onPressed: isRunning ? null : () => _leave(ref, onDone),
            ),
          ],
        ),
      ),
    );
  }
}
