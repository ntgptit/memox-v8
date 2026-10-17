import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget _empty(BuildContext context) => const SizedBox();

Widget _scrollable(BuildContext context, ScrollController controller) =>
    const SizedBox();

Future<void> openAdaptive(BuildContext context) =>
    showAdaptiveDialog<void>(context: context, builder: _empty);

Future<void> openCupertinoDialog(BuildContext context) =>
    showCupertinoDialog<void>(context: context, builder: _empty);

Future<void> openPopup(BuildContext context) =>
    showCupertinoModalPopup<void>(context: context, builder: _empty);

Future<void> openSheet(BuildContext context) =>
    showCupertinoSheet<void>(context: context, scrollableBuilder: _scrollable);

Route<void> dialogRoute(BuildContext context) =>
    CupertinoDialogRoute<void>(context: context, builder: _empty);

Route<void> popupRoute(BuildContext context) =>
    CupertinoModalPopupRoute<void>(builder: _empty);

Route<void> sheetRoute() =>
    CupertinoSheetRoute<void>(scrollableBuilder: _scrollable);

List<Widget> adaptiveControls() => [
  Switch.adaptive(value: true, onChanged: (_) {}),
  Slider.adaptive(value: 0, onChanged: (_) {}),
  const CircularProgressIndicator.adaptive(),
  Checkbox.adaptive(value: true, onChanged: (_) {}),
];

List<Widget> cupertinoControls() => [
  CupertinoSwitch(value: true, onChanged: (_) {}),
  CupertinoCheckbox(value: true, onChanged: (_) {}),
  CupertinoSlider(value: 0, onChanged: (_) {}),
  const CupertinoRadio<int>(value: 1),
  const CupertinoActivityIndicator(),
  const CupertinoAlertDialog(),
];
