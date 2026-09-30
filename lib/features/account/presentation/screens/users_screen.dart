import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/account/presentation/controllers/users_controller.dart';
import 'package:memox/features/account/presentation/states/users_state.dart';
import 'package:memox/features/account/presentation/widgets/overlays/user_role_sheet_widget.dart';
import 'package:memox/features/account/presentation/widgets/sections/users_list_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

/// Screen 33, Users (users spec §3, auth spec O9): an admin finds any
/// signed-in account by email and makes it an admin or a user. The search
/// field sits over the list, which alone scrolls, as on screen 28.
class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = ref.watch(usersControllerProvider.notifier);
    // Nothing on a refused page can be searched (as screen 28).
    final isRefused = ref.watch(
      usersControllerProvider.select(
        (state) => switch (state.content) {
          UsersFailed(failure: UsersLoadFailure.notAdmin) => true,
          _ => false,
        },
      ),
    );
    final list = UsersListWidget(
      selfId: ref.watch(currentAccountProvider)?.id,
      onOpenUser: (user) => unawaited(showUserRoleSheet(context, user)),
    );
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.usersTitle,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: isRefused
          ? list
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.grouped,
                    AppSpacing.gutter,
                    AppSpacing.control,
                  ),
                  child: MxSearchField(
                    controller: _search,
                    hintText: l10n.usersSearchHint,
                    clearLabel: l10n.usersSearchClear,
                    onChanged: controller.search,
                  ),
                ),
                Expanded(child: list),
              ],
            ),
    );
  }
}
