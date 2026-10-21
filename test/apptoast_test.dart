import 'package:apptoast/apptoast.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('ToastThemeData Unit Tests', () {
    test('resolves non-null defaults when ambient is empty', () {
      const ToastThemeData theme = ToastThemeData();
      final ToastThemeData resolved = theme.copyWith(borderRadius: 12);

      expect(resolved.borderRadius, 12);
      expect(resolved.blurSigma, 14.0);
      expect(resolved.iconSpacing, 10.0);
    });

    test('step lerp returns instant value without crash', () {
      const ToastThemeData a = ToastThemeData(borderRadius: 10);
      const ToastThemeData b = ToastThemeData(borderRadius: 20);

      expect(a.lerp(b, 0.2).borderRadius, 10);
      expect(a.lerp(b, 0.8).borderRadius, 20);
    });
  });

  group('AppToast Widget Tests', () {
    testWidgets('renders message and default success icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    AppToast.success(context, 'Saved successfully'),
                child: const Text('Show Success'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Success'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Saved successfully'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('AppToast.show renders plain text without leading icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppToast.show(context, 'Plain notice pill'),
                child: const Text('Show Plain'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Plain'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Plain notice pill'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('renders custom leading widget over default icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppToast.info(
                  context,
                  'Syncing...',
                  leading: const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(),
                  ),
                ),
                child: const Text('Show Custom'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Custom'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Syncing...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsNothing);
    });

    testWidgets('AppToast.dismiss removes active toast programmatically', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () =>
                        AppToast.warning(context, 'To be dismissed'),
                    child: const Text('Show'),
                  ),
                  ElevatedButton(
                    onPressed: AppToast.dismiss,
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('To be dismissed'), findsOneWidget);

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
      expect(find.text('To be dismissed'), findsNothing);
    });
  });
}
