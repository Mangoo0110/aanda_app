import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement.dart';

class SettlementResolutionSheet extends StatefulWidget {
  const SettlementResolutionSheet({
    super.key,
    required this.members,
    required this.colors,
    required this.onFinalise,
  });

  final List<MemberSettlementSummary> members;
  final AppColors colors;
  final void Function(List<MemberResolutionParams> resolutions) onFinalise;

  static Future<void> show({
    required BuildContext context,
    required List<MemberSettlementSummary> members,
    required AppColors colors,
    required void Function(List<MemberResolutionParams> resolutions) onFinalise,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SettlementResolutionSheet(
        members: members,
        colors: colors,
        onFinalise: onFinalise,
      ),
    );
  }

  @override
  State<SettlementResolutionSheet> createState() =>
      _SettlementResolutionSheetState();
}

class _SettlementResolutionSheetState extends State<SettlementResolutionSheet> {
  // Map of userId -> selected resolution type
  late final Map<String, BalanceResolutionType> _resolutions;
  // Map of userId -> reason controller
  late final Map<String, TextEditingController> _reasonControllers;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _resolutions = {};
    _reasonControllers = {};

    for (final m in widget.members) {
      if (m.remainingDue.abs() > 0.01) {
        _resolutions[m.userId] = BalanceResolutionType.carryForward;
        _reasonControllers[m.userId] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _reasonControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    // Validate that all miscellaneous selections have a reason
    for (final entry in _resolutions.entries) {
      if (entry.value == BalanceResolutionType.miscellaneous) {
        final reason = _reasonControllers[entry.key]?.text.trim() ?? '';
        if (reason.isEmpty) {
          setState(() {
            _validationError = 'Please provide a reason for all miscellaneous adjustments.';
          });
          return;
        }
      }
    }

    final result = <MemberResolutionParams>[];
    for (final entry in _resolutions.entries) {
      result.add(
        MemberResolutionParams(
          userId: entry.key,
          resolutionType: entry.value,
          resolutionReason: _reasonControllers[entry.key]?.text.trim(),
        ),
      );
    }

    Navigator.of(context).pop();
    widget.onFinalise(result);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final currFmt = NumberFormat('#,##0.00');
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final unresolvedMembers = widget.members
        .where((m) => m.remainingDue.abs() > 0.01)
        .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
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
            'Finalise & Settle',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unresolvedMembers.isEmpty
                ? 'All member balances are cleared. Ready to close this cycle.'
                : 'Choose how to resolve remaining member balances before closing.',
            style: TextStyle(
              fontSize: 13,
              color: colors.textColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),

          if (_validationError != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _validationError!,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // List of unresolved members
          if (unresolvedMembers.isNotEmpty)
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: unresolvedMembers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final m = unresolvedMembers[i];
                  final res = _resolutions[m.userId] ??
                      BalanceResolutionType.carryForward;
                  final isDebt = m.remainingDue > 0;
                  final absAmount = m.remainingDue.abs();

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.softGrey,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              m.displayName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: colors.textColor,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isDebt
                                    ? const Color(0xFFD32F2F).withOpacity(0.12)
                                    : const Color(0xFF388E3C).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isDebt
                                    ? 'Owes ৳ ${currFmt.format(absAmount)}'
                                    : 'House owes ৳ ${currFmt.format(absAmount)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDebt
                                      ? const Color(0xFFD32F2F)
                                      : const Color(0xFF388E3C),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Resolution choice
                        SegmentedButton<BalanceResolutionType>(
                          segments: const [
                            ButtonSegment(
                              value: BalanceResolutionType.carryForward,
                              label: Text(
                                'Carry Forward',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            ButtonSegment(
                              value: BalanceResolutionType.miscellaneous,
                              label: Text(
                                'Miscellaneous',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                          selected: {res},
                          onSelectionChanged: (set) {
                            setState(() {
                              _resolutions[m.userId] = set.first;
                              _validationError = null;
                            });
                          },
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            backgroundColor: WidgetStateProperty.resolveWith(
                              (states) {
                                if (states.contains(WidgetState.selected)) {
                                  return colors.textColor;
                                }
                                return colors.appBackgroundColor;
                              },
                            ),
                            foregroundColor: WidgetStateProperty.resolveWith(
                              (states) {
                                if (states.contains(WidgetState.selected)) {
                                  return colors.invertTextColor;
                                }
                                return colors.textColor;
                              },
                            ),
                          ),
                        ),

                        // Reason field if miscellaneous
                        if (res == BalanceResolutionType.miscellaneous) ...[
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _reasonControllers[m.userId],
                            maxLength: 300,
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textColor,
                            ),
                            decoration: InputDecoration(
                              hintText: isDebt
                                  ? 'Reason (e.g. Paid offline via cash / waived)'
                                  : 'Reason (e.g. Refunded to member via bKash)',
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: colors.textColor.withOpacity(0.4),
                              ),
                              filled: true,
                              fillColor: colors.appBackgroundColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 20),

          // Confirm button
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
                'Confirm & Close Cycle',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
