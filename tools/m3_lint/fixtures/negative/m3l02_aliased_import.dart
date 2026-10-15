import 'package:flutter/cupertino.dart' as c;
import 'package:flutter/material.dart';

Future<void> openAliased(BuildContext context) => c.showCupertinoDialog<void>(
  context: context,
  builder: (_) => const SizedBox(),
);

Widget adaptiveSwitch() => Switch.adaptive(value: true, onChanged: (_) {});
