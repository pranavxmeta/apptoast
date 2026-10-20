import 'package:material_ui/material_ui.dart';

/// Enhanced enum binding default visual identity to each toast variant.
enum ToastType(final Color accentColor, final IconData icon) {
  info(Color(0xFFFF9000), Icons.info_outline),
  success(Color(0xFF34C759), Icons.check_circle_outline),
  warning(Color(0xFFFFCC00), Icons.warning_amber_rounded),
  error(Color(0xFFFF3B30), Icons.error_outline);
}

/// Immutable data payload passed to the toast presenter.
/// Uses Dart 3.13 primary constructor declaring parameters.
@immutable
class const ToastPayload({
  required final String message,
  final ToastType type = ToastType.info,
  final Duration duration = const Duration(milliseconds: 2400),
  final IconData? customIcon,
  final Widget? leading,
  final bool showIcon = true,
  final VoidCallback? onDismiss,
});
