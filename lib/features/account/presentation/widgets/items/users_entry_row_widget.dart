import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

/// Screen 23's Users row (users spec §4), under Monitoring in the Admin
/// section that Settings shows only to an admin (U2); `app/` hands it in.
class UsersEntryRowWidget extends StatelessWidget {
  const UsersEntryRowWidget({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxSettingsRow(
      label: l10n.usersTitle,
      subtitle: l10n.usersRowHint,
      icon: AppIcons.users,
      onTap: onOpen,
    );
  }
}
