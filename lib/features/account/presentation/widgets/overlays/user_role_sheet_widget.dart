import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/account/domain/models/managed_user_model.dart';
import 'package:memox/features/account/presentation/controllers/users_controller.dart';
import 'package:memox/features/account/presentation/states/users_state.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Opens [user]'s role sheet (users spec §3).
Future<void> showUserRoleSheet(BuildContext context, ManagedUser user) =>
    showMxBottomSheet<void>(
      context,
      builder: (_) => UserRoleSheetWidget(user: user),
    );

/// User or Admin for one account, in the merge sheet's form (spec §6). The
/// sheet runs the change itself (P4 plan ruling 4): Save spins, a refusal
/// keeps the sheet and says why, a success closes it.
class UserRoleSheetWidget extends ConsumerStatefulWidget {
  const UserRoleSheetWidget({super.key, required this.user});

  final ManagedUser user;

  @override
  ConsumerState<UserRoleSheetWidget> createState() =>
      _UserRoleSheetWidgetState();
}

class _UserRoleSheetWidgetState extends ConsumerState<UserRoleSheetWidget> {
  late var _choice = widget.user.role;
  var _isSaving = false;

  /// Why the last save was refused, said inside the sheet (final review I2).
  String? _problem;

  void _choose(AccountRole role) {
    if (_isSaving) return;
    setState(() {
      _choice = role;
      _problem = null;
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final change = await ref
        .read(usersControllerProvider.notifier)
        .setRole(widget.user, _choice);
    if (!mounted) return;
    final l10n = context.l10n;
    final email = widget.user.email;
    // What closes the sheet is a toast on the screen; what keeps it open is
    // said inside it, where a toast would sit behind (final review I2).
    final problem = switch (change) {
      RoleChange.lastAdmin => l10n.usersLastAdmin,
      RoleChange.anonymous => l10n.usersAnonymous,
      RoleChange.offline => l10n.usersOffline,
      RoleChange.failed => l10n.usersSaveFailed,
      _ => null,
    };
    if (problem != null) {
      setState(() {
        _isSaving = false;
        _problem = problem;
      });
      return;
    }
    final toast = switch (change) {
      RoleChange.saved =>
        _choice == AccountRole.admin
            ? l10n.usersNowAdmin(email)
            : l10n.usersNowUser(email),
      RoleChange.gone => l10n.usersGone,
      _ => null,
    };
    if (toast != null) showMxSnackbar(context, message: toast);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canSave = _choice != widget.user.role && !_isSaving;
    // Held while saving: Back, a scrim tap and a drag wait, so the answer
    // always has a sheet to be said in (P4 minor M3).
    return MxBottomSheet(
      isHeld: _isSaving,
      title: widget.user.email,
      footer: MxSheetActions(
        isInSheet: true,
        cancelLabel: l10n.commonCancel,
        onCancel: _isSaving ? null : () => Navigator.of(context).pop(),
        confirmLabel: l10n.usersSave,
        isConfirmLoading: _isSaving,
        onConfirm: canSave ? () => unawaited(_save()) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MxOptionRow(
            title: l10n.usersRoleUser,
            description: l10n.usersRoleUserHint,
            isSelected: _choice == AccountRole.user,
            onSelected: () => _choose(AccountRole.user),
          ),
          MxOptionRow(
            title: l10n.usersRoleAdmin,
            description: l10n.usersRoleAdminHint,
            isSelected: _choice == AccountRole.admin,
            onSelected: () => _choose(AccountRole.admin),
            hasDivider: false,
          ),
          if (_problem case final text?)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.grouped,
                AppSpacing.gutter,
                0,
              ),
              // Nothing changed, so the warning tone.
              child: MxInlineBanner(tone: MxBannerTone.warning, message: text),
            ),
        ],
      ),
    );
  }
}
