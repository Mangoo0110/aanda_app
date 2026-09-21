import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/house/presentation/bloc/house_detail/house_detail_bloc.dart';

/// Dialog to configure and launch a new billing cycle / sprint.
class CreateSprintDialog extends StatefulWidget {
  const CreateSprintDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<HouseDetailBloc>(),
        child: const CreateSprintDialog(),
      ),
    );
  }

  @override
  State<CreateSprintDialog> createState() => _CreateSprintDialogState();
}

class _CreateSprintDialogState extends State<CreateSprintDialog> {
  late final TextEditingController _nameCtrl;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _nameCtrl = TextEditingController(text: 'Cycle');
    _startDate = now;
    _endDate = now.add(const Duration(days: 14));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return AlertDialog(
      backgroundColor: colors.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        'New Cycle',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: colors.textColor,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'Cycle Name / Label',
              filled: true,
              fillColor: colors.appBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.date_range_rounded,
              color: colors.primaryColor,
            ),
            title: Text(
              '${DateFormat('d MMM').format(_startDate)} - ${DateFormat('d MMM').format(_endDate)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.textColor,
              ),
            ),
            subtitle: Text(
              'Tap to pick date range',
              style: TextStyle(fontSize: 11, color: colors.grey),
            ),
            onTap: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                initialDateRange: DateTimeRange(
                  start: _startDate,
                  end: _endDate,
                ),
              );
              if (range != null) {
                setState(() {
                  _startDate = range.start;
                  _endDate = range.end;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: colors.grey)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colors.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            final label = _nameCtrl.text.trim();
            if (label.isEmpty) return;
            Navigator.of(context).pop();
            // Sprint creation is no longer used;
            // settlements are now date-range based via the FAB.
          },
          child: const Text('Start Cycle'),
        ),
      ],
    );
  }
}
