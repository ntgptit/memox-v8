import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';

/// A session's lone moment: centred between the bars when it fits,
/// scrolled from the top when it does not (critique 2026-09-30 part 3c-1,
/// R4; part 3c-2, R5). Study-local: the summary and Guess's blocked notice
/// use it.
class StudyCentredScrollWidget extends StatelessWidget {
  const StudyCentredScrollWidget({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsetsDirectional.only(
          start: context.screenMargin,
          end: context.screenMargin,
          bottom: context.dimens.space24 + bottomInset,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: math.max(
              0,
              constraints.maxHeight - context.dimens.space24 - bottomInset,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}
