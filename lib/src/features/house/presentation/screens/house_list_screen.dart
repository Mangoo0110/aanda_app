import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/house/domain/entities/house.dart';
import 'package:aanda/src/features/house/presentation/bloc/house_list/house_list_bloc.dart';

/// Home screen — shown after login. Displays the user's houses or an
/// empty state with "Create" / "Join" buttons.
class HouseListScreen extends StatefulWidget {
  const HouseListScreen({super.key});

  @override
  State<HouseListScreen> createState() => _HouseListScreenState();
}

class _HouseListScreenState extends State<HouseListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HouseListBloc>().add(HouseListStarted());
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Scaffold(
      backgroundColor: colors.appBackgroundColor,
      appBar: AppBar(
        backgroundColor: colors.appBackgroundColor,
        title: Text('My Houses', style: TextStyle(color: colors.textColor)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colors.iconColor),
            onPressed: () =>
                context.read<HouseListBloc>().add(HouseListRefreshRequested()),
          ),
        ],
      ),
      body: BlocBuilder<HouseListBloc, HouseListState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (state.status == HouseListStatus.failure) {
            return _ErrorView(
              message: state.errorMessage ?? 'Failed to load houses.',
              onRetry: () => context.read<HouseListBloc>().add(
                HouseListRefreshRequested(),
              ),
            );
          }

          if (state.houses.isEmpty) {
            return _EmptyView();
          }

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<HouseListBloc>().add(HouseListRefreshRequested()),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.houses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _HouseTile(house: state.houses[i]),
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'create-house',
            onPressed: () async {
              await context.push(AppRoutes.houseCreate);
              if (context.mounted) {
                context.read<HouseListBloc>().add(HouseListRefreshRequested());
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Create'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'join-house',
            onPressed: () async {
              await context.push(AppRoutes.houseJoin);
              if (context.mounted) {
                context.read<HouseListBloc>().add(HouseListRefreshRequested());
              }
            },
            icon: const Icon(Icons.vpn_key_outlined),
            label: const Text('Join'),
          ),
        ],
      ),
    );
  }
}

class _HouseTile extends StatelessWidget {
  const _HouseTile({required this.house});
  final House house;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    return Card(
      elevation: 0,
      color: colors.tileColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colors.primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.home_work_rounded, color: Colors.white),
        ),
        title: Text(
          house.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colors.textColor,
          ),
        ),
        subtitle: Text(
          'Created: ${house.createdAt.day}/${house.createdAt.month}/${house.createdAt.year}',
          style: TextStyle(color: colors.grey, fontSize: 12),
        ),
        trailing: Icon(Icons.chevron_right, color: colors.grey),
        onTap: () => context.push(AppRoutes.houseDetail(house.id)),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 72,
              color: colors.grey.withAlpha(120),
            ),
            const SizedBox(height: 16),
            Text(
              'No houses yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a house or join one using an invite code.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: colors.errorColor),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: colors.textColor)),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
