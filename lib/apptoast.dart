import 'dart:async';
import 'dart:ui';

import 'package:material_ui/material_ui.dart';

/// Callable enum for toast variants and global presentation.
/// Uses Dart 3.13 primary constructor declaring parameters.
enum AppToast(final Color? accentColor, final Widget? defaultWidget) {
  info(Color(0xFFFF9000), Icon(Icons.info_outline)),
  success(Color(0xFF34C759), Icon(Icons.check_circle_outline)),
  warning(Color(0xFFFFCC00), Icon(Icons.warning_amber_rounded)),
  error(Color(0xFFFF3B30), Icon(Icons.error_outline)),
  show(null, null);

  static OverlayEntry? _entry;
  static GlobalKey<_ToastPillState>? _key;

  /// Direct invocation: `AppToast.success(context, 'Copied!')`.
  void call(
    BuildContext context,
    String message, {
    Widget? leading,
    Duration? duration,
    VoidCallback? onDismiss,
  }) {
    if (!context.mounted) return;

    final theme = ToastThemeData.resolve(context);
    _dismissSync();

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final key = GlobalKey<_ToastPillState>();
    _key = key;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _ToastPill(
              key: key,
              message: message,
              type: this,
              theme: theme,
              duration: duration ?? theme.duration,
              leading: leading,
              onDismiss: onDismiss,
              onFinished: () {
                if (_entry == entry) _dismissSync();
              },
            ),
          ),
        ),
      ),
    );

    _entry = entry;
    overlay.insert(entry);
  }

  /// Programmatic dismissal from anywhere without BuildContext.
  static void dismiss() {
    final state = _key?.currentState;
    if (state != null) {
      state.dismiss();
    } else {
      _dismissSync();
    }
  }

  static void _dismissSync() {
    _entry?.remove();
    _entry = null;
    _key = null;
  }
}

/// Minimal design tokens extension for AppToast.
/// Uses Dart 3.13 primary constructor declaring parameters.
@immutable
class const ToastThemeData({
  final Duration duration = const Duration(milliseconds: 2400),
  final double borderRadius = 20.0,
  final Color? backgroundColor,
  final Color? borderColor,
  final TextStyle? textStyle,
  final Map<AppToast, Widget>? typeWidgets,
}) extends ThemeExtension<ToastThemeData> {
  /// Resolves ambient configuration with dark/light fallbacks in a single pass.
  static ToastThemeData resolve(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ambient = Theme.of(context).extension<ToastThemeData>();

    return ToastThemeData(
      duration: ambient?.duration ?? const Duration(milliseconds: 2400),
      borderRadius: ambient?.borderRadius ?? 20.0,
      backgroundColor:
          ambient?.backgroundColor ??
          (isDark ? const Color(0xE618181B) : const Color(0xEBFFFFFF)),
      borderColor:
          ambient?.borderColor ??
          (isDark ? const Color(0x1FFFFFFF) : const Color(0x14000000)),
      textStyle:
          ambient?.textStyle ??
          TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : const Color(0xFF18181B),
            decoration: TextDecoration.none,
            letterSpacing: -0.2,
          ),
      typeWidgets: ambient?.typeWidgets,
    );
  }

  @override
  ToastThemeData copyWith({
    Duration? duration,
    double? borderRadius,
    Color? backgroundColor,
    Color? borderColor,
    TextStyle? textStyle,
    Map<AppToast, Widget>? typeWidgets,
  }) => ToastThemeData(
    duration: duration ?? this.duration,
    borderRadius: borderRadius ?? this.borderRadius,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    textStyle: textStyle ?? this.textStyle,
    typeWidgets: typeWidgets ?? this.typeWidgets,
  );

  @override
  ToastThemeData lerp(ThemeExtension<ToastThemeData>? other, double t) =>
      other is! ToastThemeData ? this : (t < 0.5 ? this : other);
}

/// Physics-driven animated toast pill.
/// Uses Dart 3.13 primary constructor declaring parameters.
class const _ToastPill({
  super.key,
  required final String message,
  required final AppToast type,
  required final ToastThemeData theme,
  required final Duration duration,
  required final VoidCallback onFinished,
  final Widget? leading,
  final VoidCallback? onDismiss,
}) extends StatefulWidget {
  @override
  State<_ToastPill> createState() => _ToastPillState();
}

class _ToastPillState extends State<_ToastPill>
    with SingleTickerProviderStateMixin {
  bool _isDismissing = false;
  Timer? _timer;

  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 200),
  );

  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeIn,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward().then((_) {
      if (mounted && !_isDismissing) {
        _timer = Timer(widget.duration, dismiss);
      }
    });
  }

  Future<void> dismiss() async {
    _timer?.cancel();
    if (!mounted || _isDismissing || _controller.isDismissed) return;
    _isDismissing = true;
    await _controller.reverse();
    if (mounted) {
      widget.onDismiss?.call();
      widget.onFinished();
    }
  }

  void _handleSwipeDismiss() {
    _timer?.cancel();
    _isDismissing = true;
    widget.onDismiss?.call();
    widget.onFinished();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final leadingWidget =
        widget.leading ??
        theme.typeWidgets?[widget.type] ??
        widget.type.defaultWidget;

    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -24.0 * (1.0 - _curve.value)),
        child: Transform.scale(
          scale: 0.94 + 0.06 * _curve.value,
          child: Opacity(opacity: _curve.value.clamp(0.0, 1.0), child: child),
        ),
      ),
      child: Dismissible(
        key: const ValueKey('apptoast_dismissible'),
        direction: DismissDirection.up,
        onDismissed: (_) => _handleSwipeDismiss(),
        child: GestureDetector(
          onTap: dismiss,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(theme.borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14.0, sigmaY: 14.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor,
                    borderRadius: BorderRadius.circular(theme.borderRadius),
                    border: Border.all(
                      color: theme.borderColor ?? Colors.transparent,
                      width: 0.75,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.25),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (leadingWidget != null) ...[
                        IconTheme(
                          data: IconThemeData(
                            size: 20,
                            color: widget.type.accentColor,
                          ),
                          child: leadingWidget,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Text(
                          widget.message,
                          style: theme.textStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
