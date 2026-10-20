import 'dart:async';
import 'dart:ui';

import 'package:material_ui/material_ui.dart';

import 'apptoast_model.dart';
import 'apptoast_theme.dart';

/// Self-governed toast pill with physics-driven entrance, wait, and exit animations.
/// Uses Dart 3.13 primary constructor declaring parameters.
class const ToastWidget({
  super.key,
  required final ToastPayload payload,
  required final bool isTopPositioned,
  required final VoidCallback onFinished,
  final ToastThemeData theme = const ToastThemeData(),
}) extends StatefulWidget {
  @override
  State<ToastWidget> createState() => ToastWidgetState();
}

class ToastWidgetState extends State<ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      ),
    );

    final Offset beginOffset = widget.isTopPositioned
        ? const Offset(0, -0.4)
        : const Offset(0, 0.4);

    _slideAnimation = Tween<Offset>(begin: beginOffset, end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeIn,
          ),
        );

    _startPresentationCycle();
  }

  void _startPresentationCycle() {
    _controller.forward().then((_) {
      if (!mounted) return;
      _dismissTimer = Timer(widget.payload.duration, dismiss);
    });
  }

  /// Reverses the presentation animation and notifies listener upon completion.
  Future<void> dismiss() async {
    _dismissTimer?.cancel();
    if (!mounted || _controller.isDismissed) return;

    await _controller.reverse();
    if (mounted) {
      widget.payload.onDismiss?.call();
      widget.onFinished();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ToastThemeData theme = widget.theme;
    final ToastPayload payload = widget.payload;

    final Color bgColor =
        theme.backgroundColor ?? const Color.fromRGBO(24, 24, 27, 0.90);
    final Color borderColor =
        theme.borderColor ?? const Color.fromRGBO(255, 255, 255, 0.12);

    return Padding(
      padding: theme.margin,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dismissible(
              key: const ValueKey('toast_dismissible_entry'),
              direction: widget.isTopPositioned
                  ? DismissDirection.up
                  : DismissDirection.down,
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
                        color: bgColor,
                        borderRadius: BorderRadius.circular(theme.borderRadius),
                        border: Border.all(color: borderColor, width: 0.75),
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
                          if (payload.showIcon) ...[
                            payload.leading ??
                                Icon(
                                  payload.customIcon ??
                                      theme.resolveIcon(payload.type),
                                  color: theme.resolveColor(payload.type),
                                  size: theme.iconSize,
                                ),
                            SizedBox(width: theme.iconSpacing),
                          ],
                          Flexible(
                            child: Text(
                              payload.message,
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
        ),
      ),
    );
  }
}
