part of 'settlement_screen.dart';

// ── Phase 3: Settlement Summary ───────────────────────────────────────────────

class _SummaryPhase extends StatelessWidget {
  const _SummaryPhase({
    required this.settlement,
    this.draft,
    this.selectedCostIds = const {},
    required this.isAdmin,
    required this.isFinalising,
    required this.colors,
  });

  final Settlement settlement;
  final SettlementDraft? draft;
  final Map<String, bool> selectedCostIds;
  final bool isAdmin;
  final bool isFinalising;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy');

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // Period label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.softGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range_rounded,
                      size: 16,
                      color: colors.textColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${dateFmt.format(settlement.fromDate)}  –  ${dateFmt.format(settlement.toDate)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Published Status Banner
              if (settlement.status == SettlementStatus.published) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.softGrey,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.textColor.withOpacity(0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        size: 20,
                        color: colors.textColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Statement Published',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Record member payments below. Once collected, finalise the settlement and resolve any remaining balances.',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textColor.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Totals card
              _SectionLabel(label: 'COST BREAKDOWN', colors: colors),
              const SizedBox(height: 8),
              _TotalsCard(
                settlement: settlement,
                draft: draft,
                selectedCostIds: selectedCostIds,
                colors: colors,
              ),
              const SizedBox(height: 20),

              // Member breakdown
              _SectionLabel(
                label: settlement.memberSummaries.length == 1
                    ? 'SUMMARY'
                    : 'MEMBER BREAKDOWN',
                colors: colors,
              ),
              const SizedBox(height: 8),
              ...settlement.memberSummaries.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MemberSummaryCard(
                    member: m,
                    colors: colors,
                    isAdmin: isAdmin,
                    isPublished: settlement.status == SettlementStatus.published,
                  ),
                ),
              ),

              const SizedBox(height: 8),
              if (!isAdmin)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.softGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Only an admin can finalise the settlement.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: colors.grey),
                  ),
                ),
            ],
          ),
        ),

        // Bottom action bar
        if (isAdmin)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: colors.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: InkWell(
                  onTap: isFinalising
                      ? null
                      : () {
                          if (settlement.status == SettlementStatus.draft &&
                              settlement.memberSummaries.length > 1) {
                            context
                                .read<SettlementBloc>()
                                .add(SettlementPublishRequested());
                          } else if (settlement.status ==
                                  SettlementStatus.published &&
                              settlement.memberSummaries.length > 1) {
                            SettlementResolutionSheet.show(
                              context: context,
                              members: settlement.memberSummaries,
                              colors: colors,
                              onFinalise: (resolutions) {
                                context.read<SettlementBloc>().add(
                                      SettlementFinaliseWithResolutionsRequested(
                                        resolutions: resolutions,
                                      ),
                                    );
                              },
                            );
                          } else {
                            context
                                .read<SettlementBloc>()
                                .add(SettlementFinaliseRequested());
                          }
                        },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: colors.textColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isFinalising)
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.invertTextColor,
                            ),
                          )
                        else
                          Icon(
                            settlement.status == SettlementStatus.draft &&
                                    settlement.memberSummaries.length > 1
                                ? Icons.campaign_rounded
                                : Icons.check_circle_rounded,
                            size: 18,
                            color: colors.invertTextColor,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          isFinalising
                              ? 'Saving…'
                              : (settlement.status == SettlementStatus.draft &&
                                      settlement.memberSummaries.length > 1
                                  ? 'Publish Statement to House'
                                  : 'Resolve & Finalise Settlement'),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: colors.invertTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryBreakdownItem {
  final String name;
  final String? icon;
  final String typeName;
  final double amount;
  final int count;

  const _CategoryBreakdownItem({
    required this.name,
    this.icon,
    required this.typeName,
    required this.amount,
    required this.count,
  });
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.settlement,
    this.draft,
    this.selectedCostIds = const {},
    required this.colors,
  });

  final Settlement settlement;
  final SettlementDraft? draft;
  final Map<String, bool> selectedCostIds;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final currFmt = NumberFormat('#,##0.00');

    final List<_CategoryBreakdownItem> categoryItems = [];

    if (draft != null && draft!.allCosts.isNotEmpty) {
      final selectedCosts = draft!.allCosts
          .where((c) => selectedCostIds[c.id] == true)
          .toList();

      final Map<String, _CategoryBreakdownItem> groupMap = {};
      for (final c in selectedCosts) {
        final rawName = c.categoryName?.trim();
        final rawIcon = c.categoryIcon?.trim();
        final bool isIconUrl = rawIcon != null &&
            (rawIcon.startsWith('http://') || rawIcon.startsWith('https://'));

        final String categoryName;
        if (rawName != null && rawName.isNotEmpty) {
          categoryName = rawName;
        } else if (rawIcon != null && !isIconUrl && rawIcon.isNotEmpty) {
          categoryName = rawIcon;
        } else {
          categoryName = c.name.trim().isNotEmpty ? c.name.trim() : 'Other';
        }

        final type = c.costType == CostType.fixed ? 'fixed' : 'variable';
        final key = '$categoryName::$type';

        if (groupMap.containsKey(key)) {
          final prev = groupMap[key]!;
          groupMap[key] = _CategoryBreakdownItem(
            name: categoryName,
            icon: prev.icon ?? c.categoryIcon,
            typeName: type,
            amount: prev.amount + c.amount,
            count: prev.count + 1,
          );
        } else {
          groupMap[key] = _CategoryBreakdownItem(
            name: categoryName,
            icon: c.categoryIcon,
            typeName: type,
            amount: c.amount,
            count: 1,
          );
        }
      }

      categoryItems.addAll(groupMap.values.toList()
        ..sort((a, b) => b.amount.compareTo(a.amount)));
    }

    // Fallback if no draft or items found
    if (categoryItems.isEmpty) {
      if (settlement.totalFoodCost > 0) {
        categoryItems.add(_CategoryBreakdownItem(
          name: 'Food',
          typeName: 'variable',
          amount: settlement.totalFoodCost,
          count: 0,
        ));
      }
      if (settlement.totalFixedCost > 0) {
        categoryItems.add(_CategoryBreakdownItem(
          name: 'Fixed Cost',
          typeName: 'fixed',
          amount: settlement.totalFixedCost,
          count: 0,
        ));
      }
      if (settlement.totalOtherCost > 0) {
        categoryItems.add(_CategoryBreakdownItem(
          name: 'Other',
          typeName: 'variable',
          amount: settlement.totalOtherCost,
          count: 0,
        ));
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (categoryItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No costs recorded for this period',
                style: TextStyle(fontSize: 13, color: colors.grey),
              ),
            )
          else
            ...categoryItems.map(
              (item) => _CategoryRow(item: item, colors: colors),
            ),
          Divider(height: 20, color: colors.borderColor.withValues(alpha: 0.5)),
          _TotalRow(
            label: 'Total Expenses',
            value: '৳ ${currFmt.format(settlement.totalExpenses)}',
            colors: colors,
            bold: true,
          ),
          if (settlement.totalMealCount > 0) ...[
            const SizedBox(height: 4),
            _TotalRow(
              label: 'Meal Count',
              value: '${settlement.totalMealCount.toStringAsFixed(1)} meals',
              colors: colors,
            ),
            _TotalRow(
              label: 'Meal Rate',
              value: '৳ ${currFmt.format(settlement.mealRate)} / meal',
              colors: colors,
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.item,
    required this.colors,
  });

  final _CategoryBreakdownItem item;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final currFmt = NumberFormat('#,##0.00');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          if (item.icon != null && item.icon!.isNotEmpty) ...[
            CategoryIconView(
              icon: item.icon,
              categoryName: item.name,
              size: 22,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.softGrey,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.typeName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '৳ ${currFmt.format(item.amount)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    required this.colors,
    this.bold = false,
  });

  final String label;
  final String value;
  final AppColors colors;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold ? colors.textColor : colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: colors.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberSummaryCard extends StatelessWidget {
  const _MemberSummaryCard({
    required this.member,
    required this.colors,
    this.isAdmin = false,
    this.isPublished = false,
  });

  final MemberSettlementSummary member;
  final AppColors colors;
  final bool isAdmin;
  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    final currFmt = NumberFormat('#,##0.00');
    final effectiveDue = isPublished ? member.remainingDue : member.payable;
    final owes = effectiveDue > 0.01;       // Member needs to pay/deposit to house
    final isOwed = effectiveDue < -0.01;    // Member to receive refund from house

    final Color statusColor;
    final Color badgeBg;
    final String statusText;
    final String amountText;

    if (owes) {
      statusColor = colors.errorColor;
      badgeBg = colors.errorColor.withValues(alpha: 0.1);
      statusText = isPublished ? 'Remaining Due' : 'To Pay';
      amountText = '-৳ ${currFmt.format(effectiveDue.abs())}';
    } else if (isOwed) {
      statusColor = Colors.green.shade700;
      badgeBg = Colors.green.withValues(alpha: 0.1);
      statusText = 'To Receive';
      amountText = '+৳ ${currFmt.format(effectiveDue.abs())}';
    } else {
      statusColor = colors.grey;
      badgeBg = colors.softGrey;
      statusText = 'Settled';
      amountText = '৳ 0.00';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colors.textColor.withValues(alpha: 0.08),
                backgroundImage: getAvatarImageProvider(member.avatarUrl),
                child: member.avatarUrl == null || member.avatarUrl!.isEmpty
                    ? Text(
                        member.displayName.isNotEmpty
                            ? member.displayName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colors.textColor,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                amountText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: colors.borderColor.withValues(alpha: 0.4)),
          const SizedBox(height: 10),

          // Details grid
          Row(
            children: [
              _StatCell(
                label: 'Expenses',
                value: '৳ ${currFmt.format(member.totalPaid)}',
                colors: colors,
              ),
              if (member.advanceDeposits > 0)
                _StatCell(
                  label: 'Advance',
                  value: '৳ ${currFmt.format(member.advanceDeposits)}',
                  colors: colors,
                ),
              _StatCell(
                label: 'Share',
                value: '৳ ${currFmt.format(member.totalOwed)}',
                colors: colors,
              ),
              _StatCell(
                label: 'Net Deposit',
                value: '৳ ${currFmt.format(member.netDeposit)}',
                colors: colors,
              ),
            ],
          ),

          // Carry forward balance indicator
          if (member.carryForwardIn.abs() > 0.01) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.softGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 13,
                    color: colors.textColor.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      member.carryForwardIn > 0
                          ? 'Carry forward from previous cycle: -৳ ${currFmt.format(member.carryForwardIn)} (Due)'
                          : 'Carry forward from previous cycle: +৳ ${currFmt.format(member.carryForwardIn.abs())} (Credit)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.textColor.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Collection & Payment Row (When Published)
          if (isPublished) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: colors.borderColor.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statement Due: ৳ ${currFmt.format(member.payable)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textColor.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Collected: ৳ ${currFmt.format(member.settlementDeposits)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.textColor,
                      ),
                    ),
                  ],
                ),
                if (isAdmin && member.remainingDue > 0.01)
                  FilledButton.icon(
                    onPressed: () {
                      SettlementDepositDialog.show(
                        context: context,
                        member: member,
                        colors: colors,
                        onDepositSubmitted: (amount, note) {
                          context.read<SettlementBloc>().add(
                                SettlementDepositRecordRequested(
                                  userId: member.userId,
                                  amount: amount,
                                  note: note,
                                ),
                              );
                        },
                      );
                    },
                    icon: const Icon(Icons.add_card_rounded, size: 14),
                    label: const Text(
                      'Record Payment',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: colors.textColor,
                      foregroundColor: colors.invertTextColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.colors,
  });

  final String label;
  final String value;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.colors});

  final String label;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: colors.grey,
      ),
    );
  }
}
