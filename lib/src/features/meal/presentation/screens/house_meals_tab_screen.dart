import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:aanda/src/app/bloc/house_context/house_context_cubit.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/shared/widget/empty_state_view.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/house/domain/usecases/house_usecases.dart';
import 'package:aanda/src/features/house/presentation/widgets/facebook_account_switcher_sheet.dart';
import 'package:aanda/src/features/meal/domain/usecases/meal_usecases.dart';
import 'package:aanda/src/features/meal/presentation/bloc/house_meals/house_meals_bloc.dart';
import 'package:aanda/src/features/meal/presentation/screens/house_meals_screen.dart';

class HouseMealsTabScreen extends StatelessWidget {
  const HouseMealsTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Scaffold(
      backgroundColor: colors.appBackgroundColor,
      body: SafeArea(
        child: BlocBuilder<HouseContextCubit, HouseContextState>(
          builder: (context, houseCtxState) {
            if (houseCtxState.isPersonalView) {
              return EmptyStateView(
                title: 'Meal Log is for Shared Houses',
                subtitle:
                    'You are currently in Personal Account. Switch to a shared house to record and view meal attendance.',
                icon: Icons.restaurant_menu_rounded,
                action: ElevatedButton.icon(
                  onPressed: () {
                    if (houseCtxState.hasSharedHouses) {
                      FacebookAccountSwitcherSheet.show(context);
                    } else {
                      context.push(AppRoutes.houseCreate);
                    }
                  },
                  icon: Icon(
                    houseCtxState.hasSharedHouses
                        ? Icons.sync_alt_rounded
                        : Icons.add_rounded,
                  ),
                  label: Text(
                    houseCtxState.hasSharedHouses
                        ? 'Switch to House'
                        : 'Create House',
                  ),
                ),
              );
            }

            final house = houseCtxState.selectedHouse;
            if (house == null) {
              return EmptyStateView(
                title: 'No House Selected',
                subtitle: 'Select or join a shared house to view meal logs.',
                icon: Icons.home_work_rounded,
                action: ElevatedButton.icon(
                  onPressed: () => FacebookAccountSwitcherSheet.show(context),
                  icon: const Icon(Icons.sync_alt_rounded),
                  label: const Text('Select House'),
                ),
              );
            }

            return BlocProvider<HouseMealsBloc>(
              key: ValueKey('house_meals_${house.id}'),
              create: (ctx) => HouseMealsBloc(
                houseId: house.id,
                cycleId: '',
                getHouseMembers: ctx.read<GetHouseMembers>(),
                getMealLogs: ctx.read<GetMealLogs>(),
                upsertMealLog: ctx.read<UpsertMealLog>(),
                getSprints: ctx.read<GetSprints>(),
              )..add(const HouseMealsStarted()),
              child: HouseMealsScreen(
                houseId: house.id,
                cycleId: '',
                showBackButton: false,
              ),
            );
          },
        ),
      ),
    );
  }
}
