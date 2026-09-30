import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/account/domain/models/managed_user_model.dart';
import 'package:memox/features/account/presentation/controllers/users_controller.dart';
import 'package:memox/features/account/presentation/states/users_state.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
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

  void _choose(AccountRole role) {
    if (!_isSaving) setState(() => _choice = role);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final change = await ref
        .read(usersControllerProvider.notifier)
        .setRole(widget.user, _choice);
    if (!mounted) return;
    final l10n = context.l10n;
    final email = widget.user.email;
    final message = switch (change) {
      RoleChange.saved =>
        _choice == AccountRole.admin
            ? l10n.usersNowAdmin(email)
            : l10n.usersNowUser(email),
      RoleChange.lastAdmin => l10n.usersLastAdmin,
      RoleChange.anonymous => l10n.usersAnonymous,
      RoleChange.gone => l10n.usersGone,
      RoleChange.offline => l10n.usersOffline,
      RoleChange.failed => l10n.usersSaveFailed,
      RoleChange.notAdmin => null,
    };
    final closes = switch (change) {
      RoleChange.saved || RoleChange.gone || RoleChange.notAdmin => true,
      _ => false,
    };
    if (message != null) showMxSnackbar(context, message: message);
    if (closes) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canSave = _choice != widget.user.role && !_isSaving;
    return PopScope(
      canPop: !_isSaving,
      child: MxBottomSheet(
        header: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.card,
            AppSpacing.micro,
            AppSpacing.card,
            AppSpacing.grouped,
          ),
          child: Text(
            widget.user.email,
            style: context.textStyles.compactTitle,
          ),
        ),
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
          ],
        ),
      ),
    );
  }
}
