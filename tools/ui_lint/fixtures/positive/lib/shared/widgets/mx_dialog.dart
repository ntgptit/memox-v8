import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

// The overlay adapter may push ForUI's dialog route and subclass it.
abstract class OwnDialogRoute extends FDialogRoute<void> {
  OwnDialogRoute({required super.builder, required super.style});
}

Future<void> openDialog(BuildContext context) => showFDialog<void>(
  context: context,
  builder: (context, style, animation) => const SizedBox(),
);
