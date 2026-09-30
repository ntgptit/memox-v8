import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/features/account/presentation/widgets/sections/code_form_widget.dart';
import 'package:memox/features/account/presentation/widgets/support/account_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// Screen 31 (account UI spec §5.2): the six digits sent to [email].
class CodeScreen extends ConsumerWidget {
  const CodeScreen({super.key, required this.email, required this.onSignedIn});

  final String email;

  /// The account is attached: the flow closes (plan ruling 2).
  final VoidCallback onSignedIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    void back() => unawaited(Navigator.of(context).maybePop());
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.accountCodeTitle,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: back,
        ),
      ),
      body: MxScreenScroll(
        children: [
          CodeFormWidget(
            email: email,
            purpose: SignInPurpose.link,
            onUseAnotherEmail: back,
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
