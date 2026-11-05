import 'dart:async';

import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

/// Enables leak tracking for the tests in this directory.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  LeakTesting.enable();
  await testMain();
}
