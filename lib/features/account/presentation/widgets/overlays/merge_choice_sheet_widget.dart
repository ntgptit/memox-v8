import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/account/domain/models/local_library_model.dart';
import 'package:memox/features/account/presentation/providers/count_local_library_use_case_provider.dart';
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
/// from there.
Future<bool> startLinkSwitch(
  BuildContext context,
  WidgetRef ref, {
  String? email,
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
  try {
    await accounts.beginSwitch(choice: choice, targetHint: email);
    return true;
  } on Failure catch (error) {
    if (context.mounted) {
      showMxSnackbar(context, message: context.l10n.failure(error));
    }
    return false;
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
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.micro,
          AppSpacing.card,
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
