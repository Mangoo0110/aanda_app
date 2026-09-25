import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/bloc/house_context/house_context_cubit.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/shared/widget/amount_text.dart';
import '../../../../core/shared/widget/app_card.dart';
import '../../../../core/shared/widget/app_page_header.dart';
import '../../../../core/shared/widget/app_section_header.dart';
import '../../../../core/shared/widget/empty_state_view.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../house/domain/entities/house_member.dart';
import '../../../house/domain/usecases/get_house_members.dart';
import '../../data/datasources/deposit_remote_datasource.dart';
import '../../../../core/async_handlers/response.dart';
import '../../domain/entities/deposit.dart';
import '../../domain/entities/settlement.dart';
import '../bloc/settlement_bloc.dart';
import '../widgets/deposit_detail_sheet.dart';
import '../widgets/record_deposit_sheet.dart';
import '../widgets/settlement_breakdown_sheet.dart';

class SettlementTabScreen extends StatefulWidget {
  const SettlementTabScreen({super.key});

  @override
  State<SettlementTabScreen> createState() => _SettlementTabScreenState();
}

class _SettlementTabScreenState extends State<SettlementTabScreen> {
  String? _lastLoadedHouseId;
  int _selectedSegment = 0; // 0 = Settlements, 1 = Member Deposits
  List<Deposit> _deposits = [];
  Map<String, HouseMember> _membersMap = {};
  bool _isLoadingDeposits = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndLoadHistory();
  }

  void _checkAndLoadHistory() {
    final houseState = context.read<HouseContextCubit>().state;
    final activeAccount =
        houseState.activeAccount ?? houseState.personalAccount;
    final houseId = activeAccount?.id;
    if (houseId != null && houseId != _lastLoadedHouseId) {
      _lastLoadedHouseId = houseId;
      context.read<SettlementBloc>().add(
        SettlementHistoryRequested(houseId: houseId),
      );
      _loadDeposits(houseId);
    }
  }

  Future<void> _loadDeposits(String houseId) async {
    if (!mounted) return;
    setState(() => _isLoadingDeposits = true);
    try {
      final datasource = context.read<DepositRemoteDatasource>();
      final membersUsecase = context.read<GetHouseMembers>();

      final results = await Future.wait([
        datasource.getDepositsForHouse(houseId: houseId),
        membersUsecase(houseId),
      ]);

      if (!mounted) return;

      final depositsList = results[0] as List<Deposit>;
      final membersResult = results[1] as RepoResponse<List<HouseMember>>;

      final membersMap = <String, HouseMember>{};
      if (membersResult.success && membersResult.data != null) {
        for (final m in membersResult.data!) {
          membersMap[m.userId] = m;
        }
      }

      setState(() {
        _deposits = depositsList;
        _membersMap = membersMap;
        _isLoadingDeposits = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingDeposits = false);
      }
    }
  }

  double get _totalUnsettledDeposits {
    return _deposits
        .where((d) => !d.isSettled)
        .fold(0.0, (sum, d) => sum + d.amount);
  }

  double get _totalSettledDeposits {
    return _deposits
        .where((d) => d.isSettled)
        .fold(0.0, (sum, d) => sum + d.amount);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Scaffold(
      backgroundColor: colors.appBackgroundColor,
      body: SafeArea(
        child: BlocConsumer<HouseContextCubit, HouseContextState>(
          listenWhen: (prev, curr) =>
              prev.activeAccountId != curr.activeAccountId ||
              prev.costUpdateCounter != curr.costUpdateCounter ||
              prev.mealUpdateCounter != curr.mealUpdateCounter,
          listener: (context, houseState) {
            final activeAccount =
                houseState.activeAccount ?? houseState.personalAccount;
            final houseId = activeAccount?.id;
            if (houseId != null) {
              _lastLoadedHouseId = houseId;
              context.read<SettlementBloc>().add(
                SettlementHistoryRequested(houseId: houseId),
              );
              _loadDeposits(houseId);
            }
          },
          builder: (context, houseState) {
            final activeAccount =
                houseState.activeAccount ?? houseState.personalAccount;
            final houseId = activeAccount?.id ?? '';
            final isPersonal = houseState.isPersonalView;
            final accountName = isPersonal
                ? 'Personal Account'
                : (activeAccount?.name ?? 'Shared House');
            final subtitle = isPersonal
                ? 'Personal Account'
                : accountName;

            if (houseId.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation(colors.textColor),
                  ),
                ),
              );
            }

            return RefreshIndicator(
              color: colors.textColor,
              onRefresh: () async {
                if (houseId.isNotEmpty) {
                  context.read<SettlementBloc>().add(
                    SettlementHistoryRequested(houseId: houseId),
                  );
                  await _loadDeposits(houseId);
                }
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  AppPageHeader(
                    title: 'Settlement',
                    subtitle: subtitle,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isPersonal)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => RecordDepositSheet.show(
                                context: context,
                                houseId: houseId,
                                onDepositSaved: () => _loadDeposits(houseId),
                              ),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.softGrey,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: colors.dividerColor),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add_rounded,
                                      size: 16,
                                      color: colors.textColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Deposit',
                                      style: TextStyle(
                                        color: colors.textColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        InkWell(
                          onTap: () => context.push(
                            AppRoutes.settlementStart(houseId),
                            extra: {
                              'houseName': accountName,
                              'isAdmin': true,
                            },
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: colors.textColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calculate_rounded,
                                  size: 16,
                                  color: colors.invertTextColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Start',
                                  style: TextStyle(
                                    color: colors.invertTextColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Segmented Switcher (Settlements vs Member Deposits)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colors.softGrey,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.dividerColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSegmentButton(
                              context: context,
                              title: 'Statements',
                              isSelected: _selectedSegment == 0,
                              onTap: () => setState(() => _selectedSegment = 0),
                            ),
                          ),
                          Expanded(
                            child: _buildSegmentButton(
                              context: context,
                              title: 'Member Deposits',
                              badgeCount: _deposits.isNotEmpty ? _deposits.length : null,
                              isSelected: _selectedSegment == 1,
                              onTap: () => setState(() => _selectedSegment = 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (_selectedSegment == 0) ...[
                    // ── STATEMENTS VIEW ─────────────────────────────────────────
                    // Active Settlement Action Banner
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: AppCard(
                        padding: const EdgeInsets.all(18),
                        backgroundColor: colors.softGrey,
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: colors.textColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.sync_alt_rounded,
                                color: colors.textColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ready to Settle?',
                                    style: AppTextStyles.rowTitle.copyWith(
                                      color: colors.textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isPersonal
                                        ? 'Finalize period expenses & reset cycle'
                                        : 'Compute meal rates & net member balances',
                                    style: AppTextStyles.rowSubtitle.copyWith(
                                      color: colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: colors.grey,
                            ),
                          ],
                        ),
                        onTap: () => context.push(
                          AppRoutes.settlementStart(houseId),
                          extra: {
                            'houseName': accountName,
                            'isAdmin': true,
                          },
                        ),
                      ),
                    ),

                    if (!isPersonal && _totalUnsettledDeposits > 0) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: InkWell(
                          onTap: () => setState(() => _selectedSegment = 1),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: colors.settledColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: colors.settledColor.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.account_balance_wallet_rounded,
                                    size: 20, color: colors.settledColor),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '৳${_totalUnsettledDeposits.toStringAsFixed(0)} Advance Fund Active',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: colors.textColor,
                                        ),
                                      ),
                                      Text(
                                        'Ready to be credited in next settlement',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, size: 18, color: colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    const AppSectionHeader(label: 'Past Settlements'),

                    BlocBuilder<SettlementBloc, SettlementState>(
                      builder: (context, state) {
                        if (state.isLoadingHistory) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: CircularProgressIndicator.adaptive(
                                valueColor: AlwaysStoppedAnimation(colors.textColor),
                              ),
                            ),
                          );
                        }

                        if (state.settlementHistory.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                            child: EmptyStateView(
                              padding: const EdgeInsets.all(24),
                              icon: Icons.history_rounded,
                              title: 'No settlement records yet',
                              subtitle: isPersonal
                                  ? 'When you conclude an expense period or cycle, recorded settlements will appear here.'
                                  : 'When your house concludes an expense sprint or cycle, recorded settlements will appear here.',
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: state.settlementHistory.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final s = state.settlementHistory[index];
                            return _SettlementCard(
                              settlement: s,
                              onTap: () => SettlementBreakdownSheet.show(
                                context: context,
                                settlement: s,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ] else ...[
                    // ── MEMBER DEPOSITS VIEW ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Member Deposits',
                                style: AppTextStyles.sectionHeader.copyWith(
                                  fontSize: 16,
                                  color: colors.textColor,
                                ),
                              ),
                              Text(
                                'Advance funds & direct cost contributions',
                                style: TextStyle(fontSize: 12, color: colors.grey),
                              ),
                            ],
                          ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.textColor,
                              foregroundColor: colors.invertTextColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () => RecordDepositSheet.show(
                              context: context,
                              houseId: houseId,
                              onDepositSaved: () => _loadDeposits(houseId),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text(
                              'Record',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Summary Stats Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: colors.softGrey,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: colors.dividerColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: colors.settledColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Active Advance',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '৳${_totalUnsettledDeposits.toStringAsFixed(0)}',
                                    style: AppTextStyles.amountMedium.copyWith(
                                      color: colors.textColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Pending settlement',
                                    style: TextStyle(fontSize: 11, color: colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: colors.softGrey,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: colors.dividerColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: colors.grey,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Reconciled',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '৳${_totalSettledDeposits.toStringAsFixed(0)}',
                                    style: AppTextStyles.amountMedium.copyWith(
                                      color: colors.textColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Past settlements',
                                    style: TextStyle(fontSize: 11, color: colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_isLoadingDeposits)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator.adaptive(
                            valueColor: AlwaysStoppedAnimation(colors.textColor),
                          ),
                        ),
                      )
                    else if (_deposits.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: EmptyStateView(
                          padding: const EdgeInsets.all(24),
                          icon: Icons.payments_outlined,
                          title: 'No member deposits logged',
                          subtitle:
                              'Log advance payments or mess fund contributions from flatmates here.',
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _deposits.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final dep = _deposits[index];
                          final member = _membersMap[dep.userId];
                          final memberName = member?.displayName ?? 'House Member';

                          return _DepositListItem(
                            deposit: dep,
                            member: member,
                            onTap: () => DepositDetailSheet.show(
                              context: context,
                              deposit: dep,
                              houseId: houseId,
                              memberName: memberName,
                              memberAvatarUrl: member?.avatarUrl,
                              onChanged: () => _loadDeposits(houseId),
                            ),
                          );
                        },
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    final colors = AppColors.context(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? colors.surfaceColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? colors.textColor : colors.grey,
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? colors.textColor : colors.dividerColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? colors.invertTextColor : colors.textColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DepositListItem extends StatelessWidget {
  const _DepositListItem({
    required this.deposit,
    this.member,
    required this.onTap,
  });

  final Deposit deposit;
  final HouseMember? member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final memberName = member?.displayName ?? 'House Member';
    final isSettled = deposit.isSettled;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colors.softGrey,
            backgroundImage: member?.avatarUrl != null
                ? NetworkImage(member!.avatarUrl!)
                : null,
            child: member?.avatarUrl == null
                ? Text(
                    memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.textColor,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        memberName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: colors.softGrey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        deposit.depositType == DepositType.advance ? 'Advance' : 'Direct Cost',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      DateFormat('d MMM yyyy').format(deposit.depositDate),
                      style: TextStyle(fontSize: 12, color: colors.grey),
                    ),
                    if (deposit.note != null && deposit.note!.isNotEmpty) ...[
                      Text(' • ', style: TextStyle(fontSize: 12, color: colors.grey)),
                      Flexible(
                        child: Text(
                          deposit.note!,
                          style: TextStyle(fontSize: 12, color: colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '৳${deposit.amount.toStringAsFixed(deposit.amount.truncateToDouble() == deposit.amount ? 0 : 2)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colors.textColor,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSettled
                      ? colors.settledColor.withValues(alpha: 0.12)
                      : colors.unsettledColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isSettled ? 'Reconciled' : 'Unsettled',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSettled ? colors.settledColor : colors.unsettledColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 16, color: colors.grey),
        ],
      ),
    );
  }
}

class _SettlementCard extends StatelessWidget {
  const _SettlementCard({
    required this.settlement,
    required this.onTap,
  });

  final Settlement settlement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final dateRange = settlement.dateRangeLabel;
    final hasMeals = settlement.totalMealCount > 0;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.softGrey,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Settled',
                  style: AppTextStyles.badge.copyWith(
                    color: colors.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                dateRange,
                style: AppTextStyles.rowSubtitle.copyWith(
                  color: colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Expenses',
                    style: AppTextStyles.rowSubtitle.copyWith(
                      color: colors.grey,
                    ),
                  ),
                  const SizedBox(height: 3),
                  AmountText(
                    amount: settlement.totalExpenses,
                    style: AppTextStyles.amountMedium.copyWith(
                      color: colors.textColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (hasMeals)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Meal Rate',
                      style: AppTextStyles.rowSubtitle.copyWith(
                        color: colors.grey,
                      ),
                    ),
                    const SizedBox(height: 3),
                    AmountText(
                      amount: settlement.mealRate,
                      showDecimals: true,
                      style: AppTextStyles.amountSmall.copyWith(
                        color: colors.textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: colors.dividerColor),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                settlement.memberSummaries.length == 1
                    ? 'Personal settlement'
                    : '${settlement.memberSummaries.length} members involved',
                style: AppTextStyles.caption.copyWith(color: colors.grey),
              ),
              Row(
                children: [
                  Text(
                    'View Breakdown',
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: colors.textColor,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
