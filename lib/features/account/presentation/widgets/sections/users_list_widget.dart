import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/account/domain/models/managed_user_model.dart';
import 'package:memox/features/account/presentation/controllers/users_controller.dart';
import 'package:memox/features/account/presentation/states/users_state.dart';
import 'package:memox/features/account/presentation/widgets/items/user_row_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_divided_column.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

/// Screen 33's list: one widget per state of users spec §3, in screen 28's
/// form (spec §6).
class UsersListWidget extends ConsumerWidget {
  const UsersListWidget({
    super.key,
    required this.selfId,
    required this.onOpenUser,
  });

  /// The signed-in admin's id: that row does not open the sheet (U1).
  final String? selfId;
  final ValueChanged<ManagedUser> onOpenUser;

  static const int _skeletonRows = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(usersControllerProvider);
    final controller = ref.watch(usersControllerProvider.notifier);
    return switch (state.content) {
      UsersLoading() => MxScreenScroll(
        children: [
          MxSkeletonList(
            semanticLabel: l10n.commonLoading,
            rows: _skeletonRows,
          ),
        ],
      ),
      UsersFailed(:final failure) => MxScreenScroll(
        children: [
          const SizedBox(height: AppSpacing.control),
          switch (failure) {
            UsersLoadFailure.notAdmin => MxEmptyState(
              icon: AppIcons.lock,
              title: l10n.monitoringNotAdminTitle,
              tone: MxEmptyStateTone.neutral,
              isCompact: true,
            ),
            // A network failure keeps the cloud-off glyph (critique
            // 2026-09-30 part 1).
            UsersLoadFailure.offline => MxErrorState(
              title: l10n.usersOfflineTitle,
              body: l10n.usersOfflineBody,
              icon: AppIcons.offline,
              retryLabel: l10n.commonRetry,
              onRetry: controller.retry,
            ),
            UsersLoadFailure.other => MxErrorState(
              title: l10n.usersErrorTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: controller.retry,
            ),
          },
        ],
      ),
      UsersLoaded(:final users) when users.isEmpty => _Refreshable(
        onRefresh: controller.refresh,
        child: MxScreenScroll(
          children: [
            const SizedBox(height: AppSpacing.control),
            MxEmptyState(
              icon: AppIcons.searchOff,
              title: state.query.trim().isEmpty
                  ? l10n.usersNone
                  : l10n.usersNoMatch(state.query.trim()),
              tone: MxEmptyStateTone.neutral,
              isCompact: true,
            ),
          ],
        ),
      ),
      final UsersLoaded loaded => _Rows(
        loaded: loaded,
        selfId: selfId,
        onOpenUser: onOpenUser,
      ),
    };
  }
}

/// The rows read so far and the state of the end below them. The next page
/// is asked for when the last ten rows come into view; a failed page waits
/// for its Retry.
class _Rows extends ConsumerWidget {
  const _Rows({
    required this.loaded,
    required this.selfId,
    required this.onOpenUser,
  });

  final UsersLoaded loaded;
  final String? selfId;
  final ValueChanged<ManagedUser> onOpenUser;

  static const double _prefetchExtent = 10 * AppSize.listRowMin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(usersControllerProvider.notifier);
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (loaded.more == UsersMore.idle &&
            loaded.next != null &&
            notification.metrics.extentAfter < _prefetchExtent) {
          unawaited(controller.loadMore());
        }
        return false;
      },
      child: _Refreshable(
        onRefresh: controller.refresh,
        child: MxScreenScroll(
          children: [
            const SizedBox(height: AppSpacing.control),
            MxListSectionHeader(label: context.l10n.usersSection),
            MxDividedColumn(
              children: [
                for (final user in loaded.users)
                  UserRowWidget(
                    user: user,
                    isSelf: user.id == selfId,
                    onTap: () => onOpenUser(user),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.grouped),
            _End(loaded: loaded, onRetry: controller.loadMore),
          ],
        ),
      ),
    );
  }
}

/// The spinner under the last row while a page loads, the retry when it
/// failed, "No more users" at the end.
class _End extends StatelessWidget {
  const _End({required this.loaded, required this.onRetry});

  final UsersLoaded loaded;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch ((loaded.more, loaded.next)) {
      (UsersMore.loading, _) => Center(
        child: MxSpinner(semanticLabel: l10n.commonLoading),
      ),
      (UsersMore.failed, _) => MxInlineBanner(
        tone: MxBannerTone.danger,
        message: l10n.usersLoadMoreFailed,
        actions: [
          MxButton(
            label: l10n.commonRetry,
            size: MxButtonSize.compact,
            onPressed: () => unawaited(onRetry()),
          ),
        ],
      ),
      (_, null) => Text(
        l10n.usersNoMore,
        textAlign: TextAlign.center,
        style: context.textStyles.footerCaption,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

/// Pull to refresh over a list that may be shorter than the screen, as
/// screen 28's.
class _Refreshable extends StatelessWidget {
  const _Refreshable({required this.onRefresh, required this.child});

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final behavior = ScrollConfiguration.of(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ScrollConfiguration(
        behavior: behavior.copyWith(
          physics: AlwaysScrollableScrollPhysics(
            parent: behavior.getScrollPhysics(context),
          ),
        ),
        child: child,
      ),
    );
  }
}
