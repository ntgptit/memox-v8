import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// How many semantics nodes name the route. A route that has two announces
/// the screen twice; the framework `AppBar` and the hand-set sites must not
/// both fire on one route. Call it with semantics enabled.
int routeNamingNodes(WidgetTester tester) {
  var count = 0;
  void visit(SemanticsNode node) {
    if (node.getSemanticsData().flagsCollection.namesRoute) count++;
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
  return count;
}
