import 'package:flutter/material.dart';

Widget _empty(BuildContext context) => const SizedBox();

Route<void> buildSheet(BuildContext context, Object? arguments) =>
    ModalBottomSheetRoute<void>(builder: _empty, isScrollControlled: false);

String openRestorable(BuildContext context) =>
    Navigator.of(context).restorablePush<void>(buildSheet).toString();
