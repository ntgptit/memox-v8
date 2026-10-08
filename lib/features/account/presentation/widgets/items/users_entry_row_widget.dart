import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

/// The Users row (users spec §4), in screen 23b's People section, which
/// only an admin reaches (U2, settings hub spec D4); `app/` hands it in.
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
