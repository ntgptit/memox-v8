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
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 29 (account UI spec U1, §5.1, §6): the first launch invites an
/// account. The name, an honest lead and two benefits sit on top; the ways on
/// sit in the thumb zone: Google, the one fill, while the account can link;
/// otherwise only "Continue without an account", the one usable way, with the
/// note under it (sign-in redesign 2026-10-05 S10). Every exit answers
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
        saySignedIn(context, stateAfterCommand(ref));
        _leave(ref, onDone);
      case SignInOutcome.identityTaken:
        // Answered as the switch starts, so a phone closed while it runs
        // does not show Welcome again (owner 2026-10-08).
        final isSwitching = await startLinkSwitch(
          context,
          ref,
          onSwitchStarted: () =>
              unawaited(ref.read(welcomeDueProvider.notifier).dismiss()),
        );
        if (isSwitching && context.mounted) _leave(ref, onDone);
      case SignInOutcome.failed:
        final problem = ref.read(signInControllerProvider(_link)).problem;
        if (problem == null) return;
        showMxSnackbar(
          context,
          message: signInProblemText(context.l10n, problem),
        );
      // A link never replaces an account, so no loss is asked here.
      case SignInOutcome.codeSent ||
          SignInOutcome.none ||
          SignInOutcome.unsentChanges:
        return;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canLink = ref.watch(canLinkProvider);
    final isRunning = ref.watch(signInControllerProvider(_link)).isRunning;
    final canSignIn = canLink && !isRunning;
    // A Google sign-in in flight takes the account through Validating, where
    // it cannot link: that is not offline, so the ways stay (final review F2).
    final isOffline = !canLink && !isRunning;
    // "Continue without an account": the quiet skip beside the ways in, or
    // the one fill when none of them can be used (S10).
    MxButton without(MxButtonTone tone) => MxButton(
      label: l10n.accountContinueWithout,
      tone: tone,
      isBlock: true,
      onPressed: isRunning ? null : () => _leave(ref, onDone),
    );
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
              namesRoute: true,
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
              ],
            ),
          ],
        ),
      ),
      footer: MxFooterBar(
        caption: isOffline ? l10n.accountOfflineNote : null,
        child: !isOffline
            ? Column(
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
                  without(MxButtonTone.text),
                ],
              )
            : without(MxButtonTone.primary),
      ),
    );
  }
}
