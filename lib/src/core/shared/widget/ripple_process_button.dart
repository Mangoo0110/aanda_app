import 'package:flutter/material.dart';

import '../reactive_notifier/process_notifier.dart';
import '../../theme/app_colors.dart';

class RippleProcessButton extends StatefulWidget {
  final double width;
  final double height;
  final String generalText;
  final String loadingText;
  final String errorText;
  final String doneText;
  final ProcessStatusNotifier? processStatusNotifier;
  final Color? progressIndicatorColor;
  final BorderRadius? borderRadius;
  final TextStyle? textStyle;
  final Function(ProcessStatusNotifier notifier) onPressed;

  const RippleProcessButton({
    super.key,
    required this.width,
    required this.height,
    required this.onPressed,
    this.generalText = "Generate",
    this.loadingText = "Generating",
    this.errorText = "Error",
    this.doneText = "Done",
    this.processStatusNotifier,
    this.progressIndicatorColor,
    this.borderRadius,
    this.textStyle,
  });

  @override
  State<RippleProcessButton> createState() => _RippleProcessButtonState();
}

class _RippleProcessButtonState extends State<RippleProcessButton> {
  late final ProcessStatusNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier =
        widget.processStatusNotifier ??
        ProcessStatusNotifier(initialStatus: ProcessEnabled());
    _notifier.addListener(_onChange);
  }

  @override
  void dispose() {
    _notifier.removeListener(_onChange);
    if (widget.processStatusNotifier == null) {
      _notifier.dispose();
    }
    super.dispose();
  }

  void _onChange() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _isEnabled => _notifier.status is ProcessEnabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ElevatedButton(
        onPressed: _isEnabled ? () => widget.onPressed(_notifier) : null,
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 140),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(999),
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (!_isEnabled || _notifier.status is ProcessLoading) {
              return AppColors.context(context).inActiveButtonColor;
            }
            final base = AppColors.context(context).primaryColor;
            if (states.contains(WidgetState.pressed)) {
              return Color.alphaBlend(Colors.black.withAlpha(25), base);
            }
            if (states.contains(WidgetState.hovered)) {
              return Color.alphaBlend(Colors.white.withAlpha(2), base);
            }
            return base;
          }),
          foregroundColor: WidgetStatePropertyAll(
            AppColors.context(context).invertTextColor,
          ),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return 2;
            if (states.contains(WidgetState.hovered)) return 8;
            if (states.contains(WidgetState.focused)) return 10;
            return 10;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.black.withAlpha(6);
            }
            if (states.contains(WidgetState.hovered)) {
              return Colors.black.withAlpha(4);
            }
            return null;
          }),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final style =
        widget.textStyle ??
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w700);

    switch (_notifier.status.runtimeType) {
      case const (ProcessLoading):
        return Row(
          key: const ValueKey("loading"),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.loadingText, style: style),
            const SizedBox(width: 10),
            SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: widget.progressIndicatorColor ?? Colors.white,
              ),
            ),
          ],
        );
      case const (ProcessFailed):
        return Text(
          widget.errorText,
          key: const ValueKey("error"),
          style: style,
        );
      case const (ProcessSuccess):
        return Text(widget.doneText, key: const ValueKey("done"), style: style);
      default:
        return Text(
          widget.generalText,
          key: const ValueKey("normal"),
          style: style,
        );
    }
  }
}
