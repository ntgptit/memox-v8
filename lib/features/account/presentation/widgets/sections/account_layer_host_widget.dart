import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/presentation/states/account_step_state.dart';
import 'package:memox/features/account/presentation/widgets/sections/account_transition_layer_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// The app root's account layer (account UI spec U4, §5.4). While a
/// transition blocks writes, it covers the router, hides the app from
/// TalkBack, and takes the system Back with priority over the router's
/// root dispatcher (plan ruling 9). It also says the coordinator's one-off
/// notices (plan ruling 8).
class AccountLayerHostWidget extends ConsumerStatefulWidget {
  const AccountLayerHostWidget({
    super.key,
    required this.backButtons,
    required this.child,
  });

  /// The router's root dispatcher.
  final BackButtonDispatcher backButtons;

  /// The router.
  final Widget child;

  @override
  ConsumerState<AccountLayerHostWidget> createState() =>
      _AccountLayerHostWidgetState();
}

class _AccountLayerHostWidgetState
    extends ConsumerState<AccountLayerHostWidget> {
  final _layerNavigator = GlobalKey<NavigatorState>();
  ChildBackButtonDispatcher? _heldBack;
  StreamSubscription<AccountNotice>? _notices;

  @override
  void initState() {
    super.initState();
    _notices = ref.read(accountCoordinatorProvider)?.notices.listen(_say);
    ref.listenManual(
      authStateProvider,
      (_, next) => _holdBack(isBlocking: blockingViewOf(next.value) != null),
      fireImmediately: true,
    );
  }

  void _holdBack({required bool isBlocking}) {
    final held = _heldBack;
    if (isBlocking && held == null) {
      _heldBack = widget.backButtons.createChildBackButtonDispatcher()
        ..addCallback(_onBack)
        ..takePriority();
      return;
    }
    if (isBlocking || held == null) return;
    held.removeCallback(_onBack);
    widget.backButtons.forget(held);
    _heldBack = null;
  }

  /// Back steps back inside the layer, never out of it.
  Future<bool> _onBack() async {
    await _layerNavigator.currentState?.maybePop();
    return true;
  }

  void _say(AccountNotice notice) {
    if (!mounted) return;
    final l10n = context.l10n;
    showMxSnackbar(
      context,
      message: switch (notice) {
        MergeNotDone() => l10n.accountMergeNotDone,
        DeleteRefused(failure: LastAdminFailure()) => l10n.accountLastAdmin,
        DeleteRefused() => l10n.accountDeleteRefused,
      },
    );
  }

  @override
  void dispose() {
    unawaited(_notices?.cancel());
    _holdBack(isBlocking: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBlocking =
        blockingViewOf(ref.watch(authStateProvider).value) != null;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (isBlocking)
          BlockSemantics(
            child: AccountTransitionLayerWidget(navigatorKey: _layerNavigator),
          ),
      ],
    );
  }
}
