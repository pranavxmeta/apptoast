import 'dart:ui';

import 'package:material_ui/material_ui.dart';

import 'apptoast_model.dart';

/// Design tokens and theme extension for the AppToast system.
///
/// Can be added to [ThemeData.extensions] in `core/theme/` to customize
/// toasts globally across light and dark themes.
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
  /// Resolves effective theme by combining local overrides, ambient
  /// [ThemeExtension] registered in `core/theme/`, and adaptive brightness fallbacks.
  static ToastThemeData resolve(
    BuildContext context, [
    ToastThemeData? localOverride,
  ]) {
    final ThemeData theme = Theme.of(context);
    final ToastThemeData? ambient = theme.extension<ToastThemeData>();
    final bool isDark = theme.brightness == Brightness.dark;

    final Color defaultBackground = isDark
        ? const Color.fromRGBO(24, 24, 27, 0.90)
        : const Color.fromRGBO(255, 255, 255, 0.92);

    final Color defaultBorder = isDark
        ? const Color.fromRGBO(255, 255, 255, 0.12)
        : const Color.fromRGBO(0, 0, 0, 0.08);

    final TextStyle defaultTextStyle = TextStyle(
      fontSize: 14.5,
      fontWeight: FontWeight.w500,
      color: isDark ? Colors.white : const Color(0xFF18181B),
      decoration: TextDecoration.none,
      letterSpacing: -0.2,
    );

    final ToastThemeData base =
        ambient ??
        ToastThemeData(
          backgroundColor: defaultBackground,
          borderColor: defaultBorder,
          textStyle: defaultTextStyle,
        );

    if (localOverride == null) {
      return base.copyWith(
        backgroundColor: base.backgroundColor ?? defaultBackground,
        borderColor: base.borderColor ?? defaultBorder,
        textStyle: base.textStyle ?? defaultTextStyle,
      );
    }

    return base.copyWith(
      backgroundColor: localOverride.backgroundColor,
      borderColor: localOverride.borderColor,
      textStyle: localOverride.textStyle,
      borderRadius: localOverride.borderRadius,
      padding: localOverride.padding,
      margin: localOverride.margin,
      blurSigma: localOverride.blurSigma,
      iconSize: localOverride.iconSize,
      iconSpacing: localOverride.iconSpacing,
      typeIcons: localOverride.typeIcons,
      typeColors: localOverride.typeColors,
    );
  }

  /// Resolves the icon for a given [ToastType], checking global extension overrides first.
  IconData resolveIcon(ToastType type) => typeIcons?[type] ?? type.icon;

  /// Resolves the accent color for a given [ToastType], checking global extension overrides first.
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
  }) {
    return ToastThemeData(
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
  }

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
