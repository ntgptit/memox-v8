import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/account/presentation/providers/can_link_provider.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/features/account/presentation/widgets/sections/sign_in_form_widget.dart';
import 'package:memox/features/account/presentation/widgets/support/account_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// Screen 30 in its link mode (account UI spec §5.2): attach Google or an
/// email to this device's anonymous user. Its decks stay where they are.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({
    super.key,
    required this.onCodeSent,
    required this.onSignedIn,
  });

  final ValueChanged<String> onCodeSent;

  /// The account is attached: the flow closes (plan ruling 2).
  final VoidCallback onSignedIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canLink = ref.watch(canLinkProvider);
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.accountSignIn,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: MxScreenScroll(
        children: [
          if (!canLink) ...[
            MxNote(text: l10n.accountOfflineNote),
            const SizedBox(height: AppSpacing.gutter),
          ],
          SignInFormWidget(
            purpose: SignInPurpose.link,
            isEnabled: canLink,
            onCodeSent: onCodeSent,
            onSignedIn: () {
              saySignedIn(context, attachedAccount(ref));
              onSignedIn();
            },
          ),
        ],
      ),
    );
  }
}
