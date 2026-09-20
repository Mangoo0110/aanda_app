import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:aanda/src/app/bloc/house_context/house_context_cubit.dart';
import 'package:aanda/src/app/routing/app_routes.dart';

/// Reusable modal bottom sheet to switch between Personal account and shared houses,
/// or navigate to create/join houses.
class AccountPickerSheet extends StatelessWidget {
  const AccountPickerSheet({
    super.key,
    this.onAccountSelected,
  });

  final VoidCallback? onAccountSelected;

  static const Color cardColor = Colors.white;
  static const Color primaryCoral = Color(0xFFD85A38);
  static const Color darkText = Color(0xFF1B1D1F);
  static const Color subText = Color(0xFF8C8D8E);

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onAccountSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => AccountPickerSheet(
        onAccountSelected: onAccountSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Switch Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: BlocBuilder<HouseContextCubit, HouseContextState>(
                  builder: (ctx, houseCtxState) {
                    final isPersonalSelected = houseCtxState.isPersonalView;

                    return ListView(
                      shrinkWrap: true,
                      children: [
                        // —— Personal Account option ——
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: isPersonalSelected
                                ? primaryCoral.withValues(alpha: 0.15)
                                : Colors.black.withValues(alpha: 0.05),
                            child: Icon(
                              Icons.person_rounded,
                              size: 18,
                              color: isPersonalSelected
                                  ? primaryCoral
                                  : darkText,
                            ),
                          ),
                          title: Text(
                            'My Personal Account',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isPersonalSelected
                                  ? primaryCoral
                                  : darkText,
                            ),
                          ),
                          subtitle: const Text(
                            'Only your personal expenses',
                            style: TextStyle(fontSize: 11, color: subText),
                          ),
                          trailing: isPersonalSelected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: primaryCoral,
                                  size: 20,
                                )
                              : null,
                          onTap: () {
                            ctx.read<HouseContextCubit>().selectPersonal();
                            Navigator.of(context).pop();
                            onAccountSelected?.call();
                          },
                        ),
                        Divider(
                          height: 1,
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                        if (houseCtxState.hasSharedHouses) ...[
                          // —— Shared houses ——
                          ...houseCtxState.sharedHouses.map((h) {
                            final isSelected = !isPersonalSelected &&
                                h.id == houseCtxState.selectedHouse?.id;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: isSelected
                                    ? primaryCoral.withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: 0.05),
                                child: Text(
                                  h.name.isNotEmpty
                                      ? h.name[0].toUpperCase()
                                      : 'H',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? primaryCoral : darkText,
                                  ),
                                ),
                              ),
                              title: Text(
                                h.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? primaryCoral : darkText,
                                ),
                              ),
                              subtitle: Text(
                                '${h.members.length} member${h.members.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: subText,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.restaurant_rounded,
                                      size: 20,
                                    ),
                                    color: primaryCoral,
                                    tooltip: 'Open Meals',
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      context.push(AppRoutes.houseMeals(h.id));
                                    },
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: primaryCoral,
                                      size: 20,
                                    ),
                                ],
                              ),
                              onTap: () {
                                ctx.read<HouseContextCubit>().selectHouse(h);
                                Navigator.of(context).pop();
                                onAccountSelected?.call();
                              },
                            );
                          }),
                        ] else ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: Text(
                                'No shared houses joined yet.',
                                style: TextStyle(fontSize: 12, color: subText),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Divider(
                height: 1,
                color: Colors.black.withValues(alpha: 0.06),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Create House'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryCoral,
                        side: const BorderSide(color: primaryCoral),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        final res = await context.push(AppRoutes.houseCreate);
                        if (res == true && context.mounted) {
                          context.read<HouseContextCubit>().refresh();
                          onAccountSelected?.call();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.group_add_rounded, size: 18),
                      label: const Text('Join House'),
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryCoral,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        final res = await context.push(AppRoutes.houseJoin);
                        if (res == true && context.mounted) {
                          context.read<HouseContextCubit>().refresh();
                          onAccountSelected?.call();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
