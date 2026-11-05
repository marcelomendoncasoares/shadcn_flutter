import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../test_helper.dart';

/// Mounts [child], optionally interacts with it, then unmounts it and lets the
/// leak tracker verify that every disposable created in between was disposed.
void _testNoLeaks(
  String description,
  Widget child, {
  Future<void> Function(WidgetTester tester)? interact,
}) {
  testWidgets(
    '$description does not leak after unmount',
    // TODO: stop ignoring CurvedAnimation once the animation_kit dependency
    // disposes the CurvedAnimation created by AnimatedValueBuilder.
    experimentalLeakTesting: LeakTesting.settings.withTrackedAll().withIgnored(
      classes: ['CurvedAnimation'],
    ),
    (tester) async {
      await tester.pumpWidget(SimpleApp(child: child));
      await interact?.call(tester);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

void main() {
  group('dispose', () {
    _testNoLeaks('Scaffold', const Text('content'));

    _testNoLeaks(
      'Clickable',
      Clickable(onPressed: () {}, child: const Text('Click')),
    );

    _testNoLeaks(
      'SelectedButton',
      SelectedButton(value: true, onChanged: (_) {}, child: const Text('Sel')),
    );

    _testNoLeaks('TextField', const TextField(initialValue: 'hello'));

    _testNoLeaks(
      'Select',
      Select<String>(
        value: null,
        placeholder: const Text('Choose'),
        onChanged: (_) {},
        popup: const SelectPopup<String>(
          items: SelectItemList(
            children: [
              SelectItemButton<String>(value: 'apple', child: Text('Apple')),
            ],
          ),
        ),
        itemBuilder: (context, value) => Text(value),
      ),
      interact: (tester) async {
        await tester.tap(find.text('Choose'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Apple'));
      },
    );

    _testNoLeaks(
      'Toast',
      Builder(
        builder: (context) => PrimaryButton(
          onPressed: () => showToast(
            context: context,
            showDuration: const Duration(milliseconds: 100),
            builder: (context, overlay) => const Text('toast'),
          ),
          child: const Text('Show toast'),
        ),
      ),
      interact: (tester) async {
        await tester.tap(find.text('Show toast'));
        await tester.pump();
        expect(find.text('toast'), findsOneWidget);
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(find.text('toast'), findsNothing);
      },
    );

    _testNoLeaks(
      'Dialog',
      Builder(
        builder: (context) => PrimaryButton(
          onPressed: () => showOverlay(
            context,
            const DialogConfiguration(),
            builder: (context) => const AlertDialog(title: Text('Dialog')),
          ),
          child: const Text('Open'),
        ),
      ),
      interact: (tester) async {
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Dialog'), findsOneWidget);
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();
      },
    );

    _testNoLeaks(
      'Drawer',
      Builder(
        builder: (context) => PrimaryButton(
          onPressed: () => showOverlay(
            context,
            const DrawerConfiguration(position: OverlayPosition.left),
            builder: (context) => const Text('Drawer'),
          ),
          child: const Text('Open'),
        ),
      ),
      interact: (tester) async {
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Drawer'), findsOneWidget);
        await tester.tapAt(const Offset(790, 5));
        await tester.pumpAndSettle();
      },
    );
  });
}
