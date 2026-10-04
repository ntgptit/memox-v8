import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/features/account/presentation/providers/welcome_due_provider.dart';
import 'package:memox/l10n/l10n_context.dart';

/// SP2 (S11): Welcome's one preserved action. "Continue" answers Welcome
/// (FN-ACCOUNT-001) and goes on to where the launch was headed.
class WelcomePlaceholder extends ConsumerWidget {
  const WelcomePlaceholder({super.key, required this.from});

  /// The screen this stands in for: an identifier, not copy.
  static const scrId = 'SCR-ACCOUNT-002';

  final String from;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(scrId),
              Text(l10n.placeholderBeingRebuilt),
              TextButton(
                onPressed: () => _continue(context, ref),
                child: Text(l10n.accountContinue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _continue(BuildContext context, WidgetRef ref) {
    unawaited(ref.read(welcomeDueProvider.notifier).dismiss());
    context.go(from);
  }
}
