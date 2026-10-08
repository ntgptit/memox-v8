import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/account/domain/models/local_library_model.dart';
import 'package:memox/features/account/presentation/controllers/sign_in_controller.dart';
import 'package:memox/features/account/presentation/providers/count_local_library_use_case_provider.dart';
import 'package:memox/features/account/presentation/providers/switch_code_request_provider.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/features/account/presentation/widgets/support/account_labels_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Auth spec #17 and account UI spec §5.3: the sign-in belongs to another
/// account. A phone with decks asks, merging by default; an empty one
/// moves without asking. [email] is the address typed, null for Google.
/// Returns whether the switch started; the transition layer takes over
/// from there. For Google, the account already picked signs in to the
/// target at once; for an email, the layer sends its code at once, so
/// nothing is asked twice (owner 2026-10-08). [onSwitchStarted] runs once
/// the switch is recorded, before its target signs in.
Future<bool> startLinkSwitch(
  BuildContext context,
  WidgetRef ref, {
  String? email,
  VoidCallback? onSwitchStarted,
}) async {
  final accounts = ref.read(accountCoordinatorProvider);
  if (accounts == null) return false;
  LocalLibrary? library;
  try {
    library = await ref.read(countLocalLibraryUseCaseProvider)();
  } on Failure {
    library = null; // Plan ruling 10: ask anyway, without numbers.
  }
  if (!context.mounted) return false;
  final choice = library != null && library.isEmpty
      ? TransitionChoice.discard
      : await showMxBottomSheet<TransitionChoice>(
          context,
          builder: (_) =>
              MergeChoiceSheetWidget(email: email, library: library),
        );
  if (choice == null || !context.mounted) return false;
  final codeRequest = ref.read(switchCodeRequestProvider.notifier);
  // Asked before the switch starts: the layer's form may be built as soon
  // as the switch waits for its target.
  if (email != null) codeRequest.ask(email);
  try {
    await accounts.beginSwitch(choice: choice, targetHint: email);
  } on Failure catch (error) {
    codeRequest.forget();
    if (context.mounted) {
      showMxSnackbar(context, message: context.l10n.failure(error));
    }
    return false;
  } on StateError {
    codeRequest.forget();
    // The account moved on meanwhile: it takes a switch only in Ready.
    if (context.mounted) {
      showMxSnackbar(context, message: context.l10n.failureAccount);
    }
    return false;
  }
  onSwitchStarted?.call();
  if (email == null && context.mounted) {
    await _signInPickedGoogle(context, ref, accounts);
  }
  return true;
}

/// The switch waits for its target: the Google account picked a moment ago
/// signs in to it (the coordinator keeps that credential, #17). A failure
/// leaves the layer's target sign-in to try again, and says why.
Future<void> _signInPickedGoogle(
  BuildContext context,
  WidgetRef ref,
  AccountCoordinator accounts,
) async {
  final state = accounts.state;
  if (state is! Transitioning || !state.isAwaitingTargetSignIn) return;
  final target = signInControllerProvider(SignInPurpose.target);
  // Held while it runs, so the layer's form shows it and the problem stays.
  final hold = ref.listenManual(target, (_, _) {});
  try {
    final outcome = await ref.read(target.notifier).continueWithGoogle();
    // A switch that succeeded may have taken screen 30 away meanwhile (its
    // link ends on screen 32): nothing here is read from it then.
    if (outcome != SignInOutcome.failed || !context.mounted) return;
    final problem = ref.read(target).problem;
    if (problem == null) return;
    showMxSnackbar(context, message: signInProblemText(context.l10n, problem));
  } finally {
    hold.close();
  }
}

/// Merge (default) or discard, then a confirm in the choice's own tone, so
/// losing this phone's data takes two deliberate taps (spec §5.3, O4).
class MergeChoiceSheetWidget extends StatefulWidget {
  const MergeChoiceSheetWidget({
    super.key,
    required this.email,
    required this.library,
  });

  /// The address that has an account; null for Google.
  final String? email;

  /// What merging brings; null when it could not be counted.
  final LocalLibrary? library;

  @override
  State<MergeChoiceSheetWidget> createState() => _MergeChoiceSheetWidgetState();
}

class _MergeChoiceSheetWidgetState extends State<MergeChoiceSheetWidget> {
  var _choice = TransitionChoice.merge;

  bool get _isDiscarding => _choice == TransitionChoice.discard;

  void _choose(TransitionChoice choice) => setState(() => _choice = choice);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final email = widget.email;
    final library = widget.library;
    return MxBottomSheet(
      header: Padding(
        // The rows, the banner and the footer start 16 in (L4).
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.micro,
          AppSpacing.gutter,
          AppSpacing.grouped,
        ),
        child: Text(
          email == null
              ? l10n.accountTakenGoogle
              : l10n.accountTakenEmail(email),
          style: context.textStyles.compactTitle,
        ),
      ),
      footer: MxSheetActions(
        isInSheet: true,
        cancelLabel: l10n.commonCancel,
        onCancel: () => Navigator.of(context).pop(),
        confirmLabel: _isDiscarding
            ? l10n.accountDiscardContinue
            : l10n.accountContinue,
        onConfirm: () => Navigator.of(context).pop(_choice),
        isDestructive: _isDiscarding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MxOptionRow(
            title: l10n.accountMerge,
            description: library == null
                ? l10n.accountMergePlain
                : l10n.accountMergeCounts(library.decks, library.cards),
            isSelected: !_isDiscarding,
            onSelected: () => _choose(TransitionChoice.merge),
          ),
          MxOptionRow(
            title: l10n.accountDiscard,
            description: l10n.accountDiscardBody,
            isSelected: _isDiscarding,
            onSelected: () => _choose(TransitionChoice.discard),
            hasDivider: false,
          ),
          if (_isDiscarding)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.grouped,
                AppSpacing.gutter,
                0,
              ),
              // Something is lost here, so the danger tone, not a note.
              child: MxInlineBanner(
                tone: MxBannerTone.danger,
                message: l10n.accountDiscardWarning,
              ),
            ),
        ],
      ),
    );
  }
}
