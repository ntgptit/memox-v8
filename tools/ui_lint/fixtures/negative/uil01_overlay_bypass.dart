import 'package:flutter/material.dart';

Widget _empty(BuildContext context) => const SizedBox();

Widget _page(BuildContext context, Animation<double> a, Animation<double> b) =>
    const SizedBox();

Future<void> openGeneral(BuildContext context) =>
    showGeneralDialog<void>(context: context, pageBuilder: _page);

Future<void> openRaw(BuildContext context) =>
    showRawDialog<void>(context: context, builder: _empty);

Route<void> dialogRoute(BuildContext context) =>
    DialogRoute<void>(context: context, builder: _empty);

Route<void> rawRoute() => RawDialogRoute<void>(pageBuilder: _page);

Route<void> sheetRoute() =>
    ModalBottomSheetRoute<void>(builder: _empty, isScrollControlled: false);

abstract class OwnPopupRoute extends PopupRoute<void> {}

abstract class OwnModalRoute implements ModalRoute<void> {}

Future<void> openMaterialDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: _empty);

Future<void> openMaterialSheet(BuildContext context) =>
    showModalBottomSheet<void>(context: context, builder: _empty);

void openSnackBar(BuildContext context) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('')));
