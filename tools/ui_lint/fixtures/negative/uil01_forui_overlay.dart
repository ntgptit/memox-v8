import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

Widget _empty(BuildContext context) => const SizedBox();

Future<void> openDialog(BuildContext context) => showFDialog<void>(
  context: context,
  builder: (context, style, animation) => const SizedBox(),
);

Future<void> openSheet(BuildContext context) =>
    showFSheet<void>(context: context, side: FLayout.btt, builder: _empty);

void openToast(BuildContext context) =>
    showFToast(context: context, title: const Text(''));

abstract class OwnFDialogRoute implements FDialogRoute<void> {}
