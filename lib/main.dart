import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/app/app.dart';

void main() {
  runApp(
    const ProviderScope(
      // DB errors are mapped to Failure explicitly (core/error/failure.dart);
      // Riverpod's default retry-on-error would otherwise sit a failed
      // provider in a hidden retry loop while showing AsyncLoading.
      retry: _noRetry,
      child: MemoxApp(),
    ),
  );
}

Duration? _noRetry(int retryCount, Object error) => null;
