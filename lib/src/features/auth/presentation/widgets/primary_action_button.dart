import 'package:flutter/material.dart';

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.isProcessing,
    required this.onPressed,
    this.width = double.infinity,
    this.height = 60,
    this.textStyle,
  });

  final String label;
  final bool isProcessing;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: FilledButton(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(height / 2),
          ),
          textStyle: textStyle,
        ),
        onPressed: isProcessing ? null : onPressed,
        child: isProcessing
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}
