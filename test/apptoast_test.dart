import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:apptoast/apptoast.dart';

void main() {
  group('ToastThemeData & Model Unit Tests', () {
    test('resolveIcon and resolveColor return defaults when unconfigured', () {
      const ToastThemeData theme = ToastThemeData();

      expect(theme.resolveIcon(ToastType.info), Icons.info_outline);
      expect(theme.resolveIcon(ToastType.success), Icons.check_circle_outline);
      expect(theme.resolveColor(ToastType.error), const Color(0xFFFF3B30));
    });

    test('resolveIcon and resolveColor honor custom type overrides', () {
      const ToastThemeData theme = ToastThemeData(
        typeIcons: {ToastType.success: Icons.star},
        typeColors: {ToastType.success: Colors.purple},
      );

      expect(theme.resolveIcon(ToastType.success), Icons.star);
      expect(theme.resolveColor(ToastType.success), Colors.purple);
      // Fallback remains for unspecified types
      expect(theme.resolveIcon(ToastType.error), Icons.error_outline);
    });

    test('copyWith properly updates properties', () {
      const ToastThemeData original = ToastThemeData(borderRadius: 12);
      final ToastThemeData copy = original.copyWith(borderRadius: 24);

      expect(copy.borderRadius, 24);
      expect(copy.blurSigma, original.blurSigma);
    });

    test('lerp correctly blends theme values', () {
      const ToastThemeData a = ToastThemeData(borderRadius: 10);
      const ToastThemeData b = ToastThemeData(borderRadius: 20);

      final ToastThemeData result = a.lerp(b, 0.5);
      expect(result.borderRadius, 15);
    });
  });

  group('Toast Overlay Widget Tests', () {
    testWidgets('renders message and default icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => context.appToast(
                    'Operation completed',
                    type: ToastType.success,
                  ),
                  child: const Text('Show Toast'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Operation completed'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('omits icon completely when showIcon is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () =>
                      context.appToast('Iconless toast', showIcon: false),
                  child: const Text('Show Toast'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Iconless toast'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('renders custom leading widget over default icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => context.appToast(
                    'Custom leading',
                    leading: const Text('CUSTOM_TAG'),
                  ),
                  child: const Text('Show Toast'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Custom leading'), findsOneWidget);
      expect(find.text('CUSTOM_TAG'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('respects ambient ThemeExtension configured in core/theme', (
      tester,
    ) async {
      const ToastThemeData customTheme = ToastThemeData(
        typeIcons: {ToastType.info: Icons.favorite},
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [customTheme]),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => context.appToast('Themed toast'),
                  child: const Text('Show Toast'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets(
      'auto-dismisses after duration and triggers onDismiss callback',
      (tester) async {
        bool dismissed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => context.appToast(
                      'Timed toast',
                      duration: const Duration(milliseconds: 500),
                      onDismiss: () => dismissed = true,
                    ),
                    child: const Text('Show Toast'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Toast'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Timed toast'), findsOneWidget);

        // Advance through presentation duration + reverse animation
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        expect(find.text('Timed toast'), findsNothing);
        expect(dismissed, isTrue);
      },
    );

    testWidgets('dismisses on user swipe gesture', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () =>
                      context.appToast('Swipable toast', isTop: true),
                  child: const Text('Show Toast'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Swipable toast'), findsOneWidget);

      // Drag up to dismiss top-positioned toast
      await tester.drag(find.text('Swipable toast'), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Swipable toast'), findsNothing);
    });
  });
}
