import 'package:flutter/material.dart';

Widget _empty(BuildContext context) => const SizedBox();

Future<void> openDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: _empty);

Future<void> openSheet(BuildContext context) =>
    showModalBottomSheet<void>(context: context, builder: _empty);
