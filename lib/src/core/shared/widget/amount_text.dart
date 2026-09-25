import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class AmountText extends StatelessWidget {
  const AmountText({
    super.key,
    required this.amount,
    this.currency = '৳',
    this.prefix,
    this.style,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.showDecimals = false,
  });

  final num amount;
  final String currency;
  final String? prefix;
  final TextStyle? style;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final bool showDecimals;

  static final NumberFormat _fmtNoDecimals = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _fmtWithDecimals = NumberFormat('#,##0.00', 'en_US');

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final formatter = showDecimals ? _fmtWithDecimals : _fmtNoDecimals;
    final formattedNum = formatter.format(amount.abs());
    final effectivePrefix = prefix ?? (amount < 0 ? '-' : '');

    TextStyle effectiveStyle = style ?? AppTextStyles.amountMedium;
    if (color != null || fontSize != null || fontWeight != null) {
      effectiveStyle = effectiveStyle.copyWith(
        color: color ?? effectiveStyle.color ?? colors.textColor,
        fontSize: fontSize ?? effectiveStyle.fontSize,
        fontWeight: fontWeight ?? effectiveStyle.fontWeight,
      );
    } else if (effectiveStyle.color == null) {
      effectiveStyle = effectiveStyle.copyWith(color: colors.textColor);
    }

    return Text(
      '$effectivePrefix$currency$formattedNum',
      style: effectiveStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
