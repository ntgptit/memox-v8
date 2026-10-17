// ignore_for_file: unused_import, unnecessary_import
// Each import below is a separate UIL03 case, so some are redundant.
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/material.dart' show ElevatedButton, Durations;
import 'package:flutter/src/material/switch.dart';
import 'package:material_ui/material_ui.dart' show Scaffold;

Widget plain() => const Card();

Widget prefixed() => const m.Chip(label: SizedBox());

Duration motion() => Durations.short4;

Widget button() => const ElevatedButton(onPressed: null, child: SizedBox());

Widget toggle() => const Switch(value: true, onChanged: null);
