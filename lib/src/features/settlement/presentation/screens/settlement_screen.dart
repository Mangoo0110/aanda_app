import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/core/shared/widget/app_back_button.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/core/utils/helpers/avatar_image_provider.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_type.dart';
import 'package:aanda/src/features/cost/presentation/widgets/category_icon_view.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement_draft.dart';
import 'package:aanda/src/features/settlement/presentation/bloc/settlement_bloc.dart';
import 'package:aanda/src/features/settlement/presentation/widgets/settlement_deposit_dialog.dart';
import 'package:aanda/src/features/settlement/presentation/widgets/settlement_resolution_sheet.dart';

part 'settlement_date_range_phase.dart';
part 'settlement_cost_selection_phase.dart';
part 'settlement_summary_phase.dart';
part 'settlement_done_phase.dart';

class SettlementScreen extends StatelessWidget {
  const SettlementScreen({
    super.key,
    required this.houseId,
    required this.houseName,
    required this.isAdmin,
  });

  final String houseId;
  final String houseName;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettlementBloc, SettlementState>(
      listenWhen: (prev, curr) =>
          (prev.phase != curr.phase && curr.phase == SettlementPhase.done) ||
          (prev.errorMessage == null && curr.errorMessage != null),
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.context(context).errorColor,
            ),
          );
        }
      },
      builder: (context, state) {
        final colors = AppColors.context(context);
        return Scaffold(
          backgroundColor: colors.appBackgroundColor,
          appBar: AppBar(
            backgroundColor: colors.appBackgroundColor,
            elevation: 0,
            leading: state.phase != SettlementPhase.dateRange && state.phase != SettlementPhase.done
                ? AppBackButton(
                    onPressed: () {
                      if (state.phase == SettlementPhase.costSelection) {
                        context.read<SettlementBloc>().add(
                          SettlementStarted(
                            houseId: houseId,
                            isAdmin: isAdmin,
                          ),
                        );
                      } else if (state.phase == SettlementPhase.summary) {
                        context.read<SettlementBloc>().add(
                          SettlementDateRangeSet(
                            fromDate: state.fromDate!,
                            toDate: state.toDate!,
                          ),
                        );
                      }
                    },
                  )
                : const AppBackButton(),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _phaseTitle(state.phase),
                  style: Theme.of(context).appBarTheme.titleTextStyle,
                ),
                Text(
                  houseName,
                  style: TextStyle(fontSize: 11, color: colors.grey),
                ),
              ],
            ),
          ),
          body: _buildBody(context, state, colors),
        );
      },
    );
  }

  String _phaseTitle(SettlementPhase phase) {
    return switch (phase) {
      SettlementPhase.dateRange => 'Start Settlement',
      SettlementPhase.costSelection => 'Select Costs',
      SettlementPhase.summary => 'Settlement Summary',
      SettlementPhase.done => 'Settlement Done',
    };
  }

  Widget _buildBody(
    BuildContext context,
    SettlementState state,
    AppColors colors,
  ) {
    return switch (state.phase) {
      SettlementPhase.dateRange => _DateRangePhase(
          fromDate: state.fromDate,
          toDate: state.toDate,
          isLoading: state.isLoading,
          colors: colors,
        ),
      SettlementPhase.costSelection => _CostSelectionPhase(
          state: state,
          colors: colors,
          isAdmin: isAdmin,
        ),
      SettlementPhase.summary => _SummaryPhase(
          settlement: state.previewSettlement!,
          draft: state.draft,
          selectedCostIds: state.selectedCostIds,
          isAdmin: isAdmin,
          isFinalising: state.isFinalising,
          colors: colors,
        ),
      SettlementPhase.done => _DonePhase(
          settlement: state.finalSettlement!,
          colors: colors,
        ),
    };
  }
}
