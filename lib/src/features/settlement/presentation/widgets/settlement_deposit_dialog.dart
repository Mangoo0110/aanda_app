import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement.dart';

class SettlementDepositDialog extends StatefulWidget {
  const SettlementDepositDialog({
    super.key,
    required this.member,
    required this.colors,
    required this.onDepositSubmitted,
  });

  final MemberSettlementSummary member;
  final AppColors colors;
  final void Function(double amount, String? note) onDepositSubmitted;

  static Future<void> show({
    required BuildContext context,
    required MemberSettlementSummary member,
    required AppColors colors,
    required void Function(double amount, String? note) onDepositSubmitted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SettlementDepositDialog(
        member: member,
        colors: colors,
        onDepositSubmitted: onDepositSubmitted,
      ),
    );
  }

  @override
  State<SettlementDepositDialog> createState() =>
      _SettlementDepositDialogState();
}

class _SettlementDepositDialogState extends State<SettlementDepositDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Pre-fill with remaining due if positive
    final defaultAmount = widget.member.remainingDue > 0
        ? widget.member.remainingDue.toStringAsFixed(2)
        : '';
    _amountController = TextEditingController(text: defaultAmount);
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) return;
    final note = _noteController.text.trim();
    Navigator.of(context).pop();
    widget.onDepositSubmitted(amount, note.isEmpty ? null : note);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final currFmt = NumberFormat('#,##0.00');
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      decoration: BoxDecoration(
        color: colors.appBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.softGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Record Payment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Collect settlement dues from ${widget.member.displayName}',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textColor.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),

              // Dues Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.softGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calculated Due',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textColor.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '৳ ${currFmt.format(widget.member.payable)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textColor,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Remaining Due',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textColor.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '৳ ${currFmt.format(widget.member.remainingDue > 0 ? widget.member.remainingDue : 0)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: widget.member.remainingDue > 0
                                ? const Color(0xFFD32F2F)
                                : colors.textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Amount field
              Text(
                'Deposit Amount (৳)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textColor,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textColor,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: '৳  ',
                  prefixStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textColor,
                  ),
                  filled: true,
                  fillColor: colors.softGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: widget.member.remainingDue > 0
                      ? TextButton(
                          onPressed: () {
                            _amountController.text = widget
                                .member.remainingDue
                                .toStringAsFixed(2);
                          },
                          child: Text(
                            'Full Due',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.textColor,
                            ),
                          ),
                        )
                      : null,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter deposit amount';
                  }
                  final n = double.tryParse(val.trim());
                  if (n == null || n <= 0) {
                    return 'Please enter a valid positive amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Note / Remarks field with 300 char limit
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Note / Remarks',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textColor,
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _noteController,
                    builder: (_, val, __) {
                      return Text(
                        '${val.text.length}/300',
                        style: TextStyle(
                          fontSize: 11,
                          color: val.text.length > 300
                              ? Colors.red
                              : colors.textColor.withOpacity(0.5),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _noteController,
                maxLength: 300,
                maxLines: 2,
                buildCounter: (
                  _, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) =>
                    null, // Custom counter above
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textColor,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Paid via bKash / cash to manager',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: colors.textColor.withOpacity(0.4),
                  ),
                  filled: true,
                  fillColor: colors.softGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.textColor,
                    foregroundColor: colors.invertTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Record Deposit',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
