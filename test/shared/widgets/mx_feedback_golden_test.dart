@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

import 'support/mx_harness.dart';

Widget _column(List<Widget> children) => SizedBox(
  width: 380,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 12,
    children: children,
  ),
);

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('inline_banner', 'tones'): () => _column([
      MxInlineBanner(
        tone: MxInlineBannerTone.warning,
        title: 'Reminders are off',
        message: 'System settings block MemoX notifications.',
        actions: [
          MxInlineBannerAction(
            label: 'Open settings',
            onPressed: () {},
            isPrimary: true,
          ),
          MxInlineBannerAction(label: 'Try again', onPressed: () {}),
        ],
      ),
      const MxInlineBanner(
        tone: MxInlineBannerTone.danger,
        message: "Couldn't sync. Nothing was lost; changes wait on this phone.",
      ),
    ]),
    ('empty_state', 'forms'): () => _column([
      MxEmptyState(
        icon: Icons.style_outlined,
        title: 'No decks yet',
        message: 'Make a deck, or import one you exported before.',
        action: MxEmptyStateAction(label: 'Create deck', onPressed: () {}),
        secondaryAction: MxEmptyStateAction(
          label: 'Import cards',
          onPressed: () {},
        ),
      ),
      const MxEmptyState(
        icon: Icons.check_circle_outline,
        title: 'All caught up',
        tone: MxEmptyStateTone.success,
        isCompact: true,
      ),
    ]),
    ('error_state', 'forms'): () => _column([
      MxErrorState(
        title: "Couldn't load your library",
        message: 'Nothing was lost. Try again in a moment.',
        retryLabel: 'Retry',
        onRetry: () {},
      ),
      const MxErrorState(title: 'This deck is gone'),
    ]),
    ('snackbar', 'forms'): () => const Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        _SnackbarStage(message: 'Deck saved'),
        _SnackbarStage(message: 'Deck moved to Trash', actionLabel: 'Undo'),
      ],
    ),
  };
  for (final MapEntry(key: (component, state), value: sheet)
      in sheets.entries) {
    for (final variant in mxThemes.keys) {
      testWidgets('mx_$component $state $variant', (tester) async {
        await expectMxGolden(
          tester,
          component: component,
          state: state,
          variant: variant,
          sheet: sheet(),
          // A snackbar slides in; let it land before the capture.
          settle: const Duration(milliseconds: 600),
        );
      });
    }
  }
}

/// A phone-width stage that shows one real snackbar as it opens.
class _SnackbarStage extends StatefulWidget {
  const _SnackbarStage({required this.message, this.actionLabel});

  final String message;
  final String? actionLabel;

  @override
  State<_SnackbarStage> createState() => _SnackbarStageState();
}

class _SnackbarStageState extends State<_SnackbarStage> {
  bool _isShown = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 380,
      height: 96,
      child: ScaffoldMessenger(
        child: Scaffold(
          body: Builder(
            builder: (context) {
              if (_isShown) {
                return const SizedBox.expand();
              }
              _isShown = true;
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => showMxSnackbar(
                  context,
                  message: widget.message,
                  actionLabel: widget.actionLabel,
                  onAction: widget.actionLabel == null ? null : () {},
                ),
              );
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
  }
}
