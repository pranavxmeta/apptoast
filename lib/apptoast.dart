import 'dart:async';
import 'dart:ui';

import 'package:material_ui/material_ui.dart';

/// Enhanced callable enum providing variant identity, default icons, and direct invocation.
/// Uses Dart 3.13 primary constructor declaring parameters.
enum AppToast(final Color? accentColor, final Widget? defaultWidget) {
  info(Color(0xFFFF9000), Icon(Icons.info_outline)),
  success(Color(0xFF34C759), Icon(Icons.check_circle_outline)),
  warning(Color(0xFFFFCC00), Icon(Icons.warning_amber_rounded)),
  error(Color(0xFFFF3B30), Icon(Icons.error_outline)),
  show(null, null);

  /// Callable invocation: allows `AppToast.success(context, '...')` or `AppToast.show(context, '...')`.
  void call(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 2400),
    Widget? leading,
    bool showIcon = true,
    bool isTop = true,
    ToastThemeData? theme,
    VoidCallback? onDismiss,
  }) => _show(
    context,
    message,
    this,
    duration: duration,
    leading: leading,
    showIcon: showIcon,
    isTop: isTop,
    theme: theme,
    onDismiss: onDismiss,
  );

  /// Dismisses currently presented toast from anywhere without BuildContext.
  static void dismiss() {
    final state = _key?.currentState;
    if (state != null) {
      state.dismiss();
    } else {
      _dismissSync();
    }
  }
}

@immutable
class const ToastThemeData({
  final Color? backgroundColor,
  final Color? borderColor,
  final TextStyle? textStyle,
  final double borderRadius = 20.0,
  final EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 11,
  ),
  final EdgeInsetsGeometry margin = const EdgeInsets.symmetric(horizontal: 20),
  final double blurSigma = 14.0,
  final double iconSpacing = 10.0,
  final Map<AppToast, Widget>? typeWidgets,
}) extends ThemeExtension<ToastThemeData> {
  /// Resolves ambient + local overrides with non-null per-property fallbacks.
  static ToastThemeData resolve(BuildContext context, [ToastThemeData? local]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ambient = Theme.of(context).extension<ToastThemeData>();

    return ToastThemeData(
      backgroundColor:
          local?.backgroundColor ??
          ambient?.backgroundColor ??
          (isDark ? const Color(0xE618181B) : const Color(0xEBFFFFFF)),
      borderColor:
          local?.borderColor ??
          ambient?.borderColor ??
          (isDark ? const Color(0x1FFFFFFF) : const Color(0x14000000)),
      textStyle:
          local?.textStyle ??
          ambient?.textStyle ??
          TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : const Color(0xFF18181B),
            decoration: TextDecoration.none,
            letterSpacing: -0.2,
          ),
      borderRadius: local?.borderRadius ?? ambient?.borderRadius ?? 20.0,
      padding:
          local?.padding ??
          ambient?.padding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      margin:
          local?.margin ??
          ambient?.margin ??
          const EdgeInsets.symmetric(horizontal: 20),
      blurSigma: local?.blurSigma ?? ambient?.blurSigma ?? 14.0,
      iconSpacing: local?.iconSpacing ?? ambient?.iconSpacing ?? 10.0,
      typeWidgets: local?.typeWidgets ?? ambient?.typeWidgets,
    );
  }

  @override
  ToastThemeData copyWith({
    Color? backgroundColor,
    Color? borderColor,
    TextStyle? textStyle,
    double? borderRadius,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? blurSigma,
    double? iconSpacing,
    Map<AppToast, Widget>? typeWidgets,
  }) => ToastThemeData(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    textStyle: textStyle ?? this.textStyle,
    borderRadius: borderRadius ?? this.borderRadius,
    padding: padding ?? this.padding,
    margin: margin ?? this.margin,
    blurSigma: blurSigma ?? this.blurSigma,
    iconSpacing: iconSpacing ?? this.iconSpacing,
    typeWidgets: typeWidgets ?? this.typeWidgets,
  );

  @override
  ToastThemeData lerp(ThemeExtension<ToastThemeData>? other, double t) =>
      other is! ToastThemeData ? this : (t < 0.5 ? this : other);
}

// Overlay Presentation Engine

OverlayEntry? _entry;
GlobalKey<_ToastPillState>? _key;

void _show(
  BuildContext context,
  String message,
  AppToast type, {
  required Duration duration,
  required Widget? leading,
  required bool showIcon,
  required bool isTop,
  required ToastThemeData? theme,
  required VoidCallback? onDismiss,
}) {
  if (!context.mounted) return;

  final effectiveTheme = ToastThemeData.resolve(context, theme);
  _dismissSync();

  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  final key = GlobalKey<_ToastPillState>();
  _key = key;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => SafeArea(
      child: Align(
        alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(
            top: isTop ? 16 : 0,
            bottom: isTop ? 0 : 24 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: _ToastPill(
            key: key,
            message: message,
            type: type,
            duration: duration,
            isTop: isTop,
            showIcon: showIcon,
            theme: effectiveTheme,
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

void _dismissSync() {
  _entry?.remove();
  _entry = null;
  _key = null;
}

/// Physics-driven animated pill with combined affine transform.
class const _ToastPill({
  super.key,
  required final String message,
  required final AppToast type,
  required final Duration duration,
  required final bool isTop,
  required final bool showIcon,
  required final ToastThemeData theme,
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

  Timer? _timer;

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
    final Widget? leadingWidget =
        widget.leading ??
        theme.typeWidgets?[widget.type] ??
        widget.type.defaultWidget;

    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        final double curv = _curve.value;
        return Transform.translate(
          offset: Offset(0, (widget.isTop ? -24.0 : 24.0) * (1.0 - curv)),
          child: Transform.scale(
            scale: 0.94 + 0.06 * curv,
            child: Opacity(opacity: curv.clamp(0.0, 1.0), child: child),
          ),
        );
      },
      child: Dismissible(
        key: const ValueKey('apptoast_dismissible'),
        direction: widget.isTop ? DismissDirection.up : DismissDirection.down,
        onDismissed: (_) => _handleSwipeDismiss(),
        child: GestureDetector(
          onTap: dismiss,
          child: Padding(
            padding: theme.margin,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(theme.borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: theme.blurSigma,
                  sigmaY: theme.blurSigma,
                ),
                child: Container(
                  padding: theme.padding,
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
                      if (widget.showIcon && leadingWidget != null) ...[
                        IconTheme(
                          data: IconThemeData(
                            size: 20,
                            color: widget.type.accentColor,
                          ),
                          child: leadingWidget,
                        ),
                        SizedBox(width: theme.iconSpacing),
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
