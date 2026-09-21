import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_category.dart';
import 'package:aanda/src/features/cost/presentation/bloc/cost_form/cost_form_bloc.dart';
import 'package:aanda/src/features/cost/presentation/screens/cost_category_form_screen.dart';
import 'package:aanda/src/features/cost/presentation/widgets/category_icon_view.dart';

class CostCategoryPickerSheet extends StatelessWidget {
  const CostCategoryPickerSheet({
    super.key,
    required this.state,
    required this.onCategorySelected,
  });

  final CostFormState state;
  final void Function(CostCategory category) onCategorySelected;

  static Future<void> show({
    required BuildContext context,
    required CostFormState state,
    required void Function(CostCategory category) onCategorySelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => CostCategoryPickerSheet(
        state: state,
        onCategorySelected: onCategorySelected,
      ),
    );
  }

  Future<void> _showNewCategoryDialog(BuildContext context) async {
    final houseId = state.selectedHouseId ??
        (state.availableHouses.isNotEmpty
            ? state.availableHouses.first.id
            : null);
    final houseName = state.selectedHouse?.name ??
        (state.availableHouses.isNotEmpty
            ? state.availableHouses.first.name
            : 'Personal');

    final result = await Navigator.of(context).push<CostCategory>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CostCategoryFormScreen(
          initialHouseId: houseId,
          initialHouseName: houseName,
        ),
      ),
    );

    if (!context.mounted) return;
    if (result != null) {
      context.read<CostFormBloc>().add(CostFormCategoryChanged(result));
      onCategorySelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B1D1F),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      _showNewCategoryDialog(context);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: 14,
                            color: Color(0xFF1B1D1F),
                          ),
                          SizedBox(width: 3),
                          Text(
                            'New',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1B1D1F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.availableCategories.length,
                  itemBuilder: (ctx, index) {
                    final cat = state.availableCategories[index];
                    final isSel = state.selectedCategory?.id == cat.id;

                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      leading: CategoryIconView(
                        icon: cat.icon,
                        categoryName: cat.name,
                        size: 38,
                        fallbackEmoji: '🏷️',
                      ),
                      title: Text(
                        cat.name,
                        style: TextStyle(
                          fontWeight:
                              isSel ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14,
                          color: const Color(0xFF1B1D1F),
                        ),
                      ),
                      subtitle: (cat.costNature != 'variable' &&
                              cat.defaultAmount != null &&
                              cat.defaultAmount! > 0)
                          ? Text(
                              'Default: ৳${cat.defaultAmount!.toInt()}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8C8D8E),
                              ),
                            )
                          : null,
                      trailing: isSel
                          ? const Icon(
                              Icons.check_rounded,
                              color: Color(0xFF1B1D1F),
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        context.read<CostFormBloc>().add(
                              CostFormCategoryChanged(cat),
                            );
                        onCategorySelected(cat);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
