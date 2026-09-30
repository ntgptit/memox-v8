import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/account/domain/models/managed_user_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

/// One account on screen 33 (users spec §3, §6): the person tile, the
/// email, when it joined, and its role as a badge (no chevron: a badge or a
/// chevron, never both). The admin's own row does not tap (U1), and is not
/// dimmed: it is content, not a disabled control.
class UserRowWidget extends StatelessWidget {
  const UserRowWidget({
    super.key,
    required this.user,
    required this.isSelf,
    required this.onTap,
    this.hasDivider = true,
  });

  final ManagedUser user;
  final bool isSelf;
  final VoidCallback onTap;
  final bool hasDivider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // P4 plan ruling 3: the locale's medium date, in local time.
    final joined = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(user.createdAt.toLocal());
    final isAdmin = user.role == AccountRole.admin;
    return MxListRow(
      leading: const MxIconTile(icon: AppIcons.account),
      title: user.email,
      subtitle: isSelf ? l10n.usersJoinedYou(joined) : l10n.usersJoined(joined),
      trailing: MxBadge(
        label: isAdmin ? l10n.usersRoleAdmin : l10n.usersRoleUser,
        tone: isAdmin ? MxBadgeTone.primary : MxBadgeTone.neutral,
      ),
      onTap: isSelf ? null : onTap,
      hasDivider: hasDivider,
    );
  }
}
