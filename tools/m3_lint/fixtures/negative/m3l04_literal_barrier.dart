import 'package:flutter/material.dart';

Widget _empty(BuildContext context) => const SizedBox();

Future<void> openWithBarrier(BuildContext context) => showDialog<void>(
  context: context,
  barrierColor: const Color(0x80000000),
  builder: _empty,
);

Future<void> openSheetWithBarrier(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      barrierColor: const Color(0x80000000),
      builder: _empty,
    );

Widget tintedCard() => const Card(surfaceTintColor: Color(0xFF6750A4));

Widget modalBarrier() =>
    const ModalBarrier(color: Color(0x80000000), dismissible: false);

Widget scrimmedDrawer() => const DrawerController(
  alignment: DrawerAlignment.start,
  scrimColor: Color(0x52000000),
  child: SizedBox(),
);
