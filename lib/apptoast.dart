import 'dart:async';
import 'dart:ui';

import 'package:material_ui/material_ui.dart';

/// Enhanced enum binding visual identity and defaults to each toast variant.
enum ToastType(final Color accentColor, final IconData icon) {
  info(Color(0xFFFF9000), Icons.info_outline),
  success(Color(0xFF34C759), Icons.check_circle_outline),
  warning(Color(0xFFFFCC00), Icons.warning_amber_rounded),
  error(Color(0xFFFF3B30), Icons.error_outline);
}

/// Design tokens and theme extension for the AppToast system.
/// Uses Dart 3.13 primary constructor declaring parameters.
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
  final double iconSize = 20.0,
  final double iconSpacing = 10.0,
  final Map<ToastType, IconData>? typeIcons,
  final Map<ToastType, Color>? typeColors,
}) extends ThemeExtension<ToastThemeData> {
  /// Resolves effective theme from caller context, ambient extension, and brightness.
  static ToastThemeData resolve(BuildContext context, [ToastThemeData? local]) {
    final ThemeData theme = Theme.of(context);
    final ToastThemeData? ambient = theme.extension<ToastThemeData>();
    final bool isDark = theme.brightness == Brightness.dark;

    final (Color bg, Color border, Color fg) = isDark
        ? (const Color(0xE618181B), const Color(0x1FFFFFFF), Colors.white)
        : (
            const Color(0xEBFFFFFF),
            const Color(0x14000000),
            const Color(0xFF18181B),
          );

    final TextStyle style = const TextStyle(
      fontSize: 14.5,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none,
      letterSpacing: -0.2,
    ).copyWith(color: fg);

    final ToastThemeData base =
        ambient ??
        ToastThemeData(
          backgroundColor: bg,
          borderColor: border,
          textStyle: style,
        );

    if (local == null) {
      return base.copyWith(
        backgroundColor: base.backgroundColor ?? bg,
        borderColor: base.borderColor ?? border,
        textStyle: base.textStyle ?? style,
      );
    }

    return base.copyWith(
      backgroundColor: local.backgroundColor,
      borderColor: local.borderColor,
      textStyle: local.textStyle,
      borderRadius: local.borderRadius,
      padding: local.padding,
      margin: local.margin,
      blurSigma: local.blurSigma,
      iconSize: local.iconSize,
      iconSpacing: local.iconSpacing,
      typeIcons: local.typeIcons,
      typeColors: local.typeColors,
    );
  }

  IconData resolveIcon(ToastType type) => typeIcons?[type] ?? type.icon;
  Color resolveColor(ToastType type) => typeColors?[type] ?? type.accentColor;

  @override
  ToastThemeData copyWith({
    Color? backgroundColor,
    Color? borderColor,
    TextStyle? textStyle,
    double? borderRadius,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? blurSigma,
    double? iconSize,
    double? iconSpacing,
    Map<ToastType, IconData>? typeIcons,
    Map<ToastType, Color>? typeColors,
  }) => ToastThemeData(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    textStyle: textStyle ?? this.textStyle,
    borderRadius: borderRadius ?? this.borderRadius,
    padding: padding ?? this.padding,
    margin: margin ?? this.margin,
    blurSigma: blurSigma ?? this.blurSigma,
    iconSize: iconSize ?? this.iconSize,
    iconSpacing: iconSpacing ?? this.iconSpacing,
    typeIcons: typeIcons ?? this.typeIcons,
    typeColors: typeColors ?? this.typeColors,
  );

  @override
  ToastThemeData lerp(ThemeExtension<ToastThemeData>? other, double t) {
    if (other is! ToastThemeData) return this;
    return ToastThemeData(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      borderColor: Color.lerp(borderColor, other.borderColor, t),
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t),
      borderRadius:
          lerpDouble(borderRadius, other.borderRadius, t) ?? borderRadius,
      padding: EdgeInsetsGeometry.lerp(padding, other.padding, t) ?? padding,
      margin: EdgeInsetsGeometry.lerp(margin, other.margin, t) ?? margin,
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t) ?? blurSigma,
      iconSize: lerpDouble(iconSize, other.iconSize, t) ?? iconSize,
      iconSpacing: lerpDouble(iconSpacing, other.iconSpacing, t) ?? iconSpacing,
      typeIcons: t < 0.5 ? typeIcons : other.typeIcons,
      typeColors: t < 0.5 ? typeColors : other.typeColors,
    );
  }
}

/// Overlay controller and presentation manager.
final class AppToast {
  AppToast._();

  static OverlayEntry? _activeEntry;
  static GlobalKey<_ToastPillState>? _activeKey;

  /// Main entry point for presenting toasts with caller context theme capture.
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

    final ToastThemeData effectiveTheme = ToastThemeData.resolve(
      context,
      theme,
    );
    dismiss();

    final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final GlobalKey<_ToastPillState> key = GlobalKey<_ToastPillState>();
    _activeKey = key;

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
              child: _ToastPill(
                key: key,
                message: message,
                type: type,
                duration: duration,
                isTop: isTop,
                showIcon: showIcon,
                theme: effectiveTheme,
                customIcon: customIcon,
                leading: leading,
                onDismiss: onDismiss,
                onFinished: () => _clean(entry),
              ),
            ),
          ),
        );
      },
    );

    _activeEntry = entry;
    overlay.insert(entry);
  }

  /// Programmatically triggers smooth exit on current active toast.
  static void dismiss() {
    if (_activeKey?.currentState != null) {
      _activeKey!.currentState!.dismiss();
    } else {
      _activeEntry?.remove();
      _activeEntry = null;
    }
  }

  static void _clean(OverlayEntry entry) {
    if (_activeEntry == entry) {
      _activeEntry?.remove();
      _activeEntry = null;
      _activeKey = null;
    }
  }
}

/// Ergonomic BuildContext extension.
extension ToastContextExtension on BuildContext {
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
  }) => AppToast.show(
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

  void dismissAppToast() => AppToast.dismiss();
}

/// Physics-driven animated pill without DTO layer indirection.
class const _ToastPill({
  super.key,
  required final String message,
  required final ToastType type,
  required final Duration duration,
  required final bool isTop,
  required final bool showIcon,
  required final ToastThemeData theme,
  required final VoidCallback onFinished,
  final IconData? customIcon,
  final Widget? leading,
  final VoidCallback? onDismiss,
}) extends StatefulWidget {
  @override
  State<_ToastPill> createState() => _ToastPillState();
}

class _ToastPillState extends State<_ToastPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 200),
  );

  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeIn,
  );

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller.forward().then((_) {
      if (!mounted) return;
      _timer = Timer(widget.duration, dismiss);
    });
  }

  Future<void> dismiss() async {
    _timer?.cancel();
    if (!mounted || _controller.isDismissed) return;
    await _controller.reverse();
    if (mounted) {
      widget.onDismiss?.call();
      widget.onFinished();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ToastThemeData theme = widget.theme;

    return Padding(
      padding: theme.margin,
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, child) => Opacity(
          opacity: _curve.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(
              0,
              (widget.isTop ? -24.0 : 24.0) * (1.0 - _curve.value),
            ),
            child: Transform.scale(
              scale: 0.94 + (0.06 * _curve.value),
              child: child,
            ),
          ),
        ),
        child: Dismissible(
          key: const ValueKey('apptoast_dismissible'),
          direction: widget.isTop ? DismissDirection.up : DismissDirection.down,
          onDismissed: (_) => dismiss(),
          child: GestureDetector(
            onTap: dismiss,
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
                      if (widget.showIcon) ...[
                        widget.leading ??
                            Icon(
                              widget.customIcon ??
                                  theme.resolveIcon(widget.type),
                              color: theme.resolveColor(widget.type),
                              size: theme.iconSize,
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
