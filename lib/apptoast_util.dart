import 'package:material_ui/material_ui.dart';

import 'apptoast_model.dart';
import 'apptoast_theme.dart';
import 'apptoast_widget.dart';

/// Overlay manager and static bridge for global toast presentation.
final class AppToast {
  AppToast._();

  static OverlayEntry? _activeEntry;
  static GlobalKey<ToastWidgetState>? _activeWidgetKey;

  /// Main entry point for rendering the toast overlay.
  ///
  /// Resolves [ToastThemeData] immediately against caller's [context]
  /// to bypass the overlay context detachment pitfall.
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(milliseconds: 2400),
    IconData? customIcon,
    Widget? leading,
    bool showIcon = true,
    bool isTop = true,
    ToastThemeData? theme,
    VoidCallback? onDismiss,
  }) {
    if (!context.mounted) return;

    // Resolve ambient ThemeExtension from caller context before entering overlay
    final ToastThemeData effectiveTheme = ToastThemeData.resolve(
      context,
      theme,
    );

    // Gracefully dismiss active toast before presenting a new one
    dismiss();

    final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final GlobalKey<ToastWidgetState> key = GlobalKey<ToastWidgetState>();
    _activeWidgetKey = key;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);

        return SafeArea(
          child: Align(
            alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                top: isTop ? 16 : 0,
                bottom: isTop ? 0 : (24 + viewInsets.bottom),
              ),
              child: ToastWidget(
                key: key,
                payload: ToastPayload(
                  message: message,
                  type: type,
                  duration: duration,
                  customIcon: customIcon,
                  leading: leading,
                  showIcon: showIcon,
                  onDismiss: onDismiss,
                ),
                isTopPositioned: isTop,
                theme: effectiveTheme,
                onFinished: () => _cleanEntry(entry),
              ),
            ),
          ),
        );
      },
    );

    _activeEntry = entry;
    overlay.insert(entry);
  }

  /// Programmatically triggers smooth exit on the active toast.
  static void dismiss() {
    if (_activeWidgetKey?.currentState != null) {
      _activeWidgetKey!.currentState!.dismiss();
    } else {
      _activeEntry?.remove();
      _activeEntry = null;
    }
  }

  static void _cleanEntry(OverlayEntry entry) {
    if (_activeEntry == entry) {
      _activeEntry?.remove();
      _activeEntry = null;
      _activeWidgetKey = null;
    }
  }
}

/// Ergonomic BuildContext extension for displaying toasts anywhere in the widget tree.
extension ToastContextExtension on BuildContext {
  /// General toast invocation via context.
  void appToast(
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(milliseconds: 2400),
    IconData? customIcon,
    Widget? leading,
    bool showIcon = true,
    bool isTop = true,
    ToastThemeData? theme,
    VoidCallback? onDismiss,
  }) {
    AppToast.show(
      this,
      message,
      type: type,
      duration: duration,
      customIcon: customIcon,
      leading: leading,
      showIcon: showIcon,
      isTop: isTop,
      theme: theme,
      onDismiss: onDismiss,
    );
  }

  /// Dismisses currently presented toast.
  void dismissAppToast() => AppToast.dismiss();
}
