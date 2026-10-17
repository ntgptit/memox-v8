import 'package:flutter/material.dart'
    show Durations, MaterialPageRoute, RefreshIndicator, ReorderableListView;
import 'package:flutter/widgets.dart';

// A feature uses Material infrastructure only, by name.
Duration motion() => Durations.short4;

Route<void> page() => MaterialPageRoute<void>(builder: (_) => const SizedBox());

Widget refreshable(Future<void> Function() onRefresh) => RefreshIndicator(
  onRefresh: onRefresh,
  child: ReorderableListView(onReorderItem: (_, _) {}, children: const []),
);
