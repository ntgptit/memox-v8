import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The hairline between two parts: ForUI's [FDivider] in the palette's
/// `border`, the colour of every hairline (ForUI's own divider is the fainter
/// `secondary`), inset [inset] at each end and with no space above or below.
/// The inset defaults to the rows' content edge; rows in a list take
/// [MxDividedColumn] instead of placing it by hand.
class MxDivider extends StatelessWidget {
  const MxDivider({super.key, this.inset});

  /// Space before and after the line; the space-16 content edge when null.
  final double? inset;

  @override
  Widget build(BuildContext context) => FDivider(
    style: FDividerStyleDelta.delta(
      color: context.colors.border,
      padding: EdgeInsetsGeometryDelta.value(
        EdgeInsetsDirectional.symmetric(
          horizontal: inset ?? context.dimens.space16,
        ),
      ),
    ),
  );
}
