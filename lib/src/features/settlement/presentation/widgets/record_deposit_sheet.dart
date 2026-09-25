import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/app/bloc/house_context/house_context_cubit.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/core/theme/app_theme.dart';
import 'package:aanda/src/features/house/domain/entities/house_member.dart';
import 'package:aanda/src/features/house/domain/usecases/get_house_members.dart';
import 'package:aanda/src/features/settlement/data/datasources/deposit_remote_datasource.dart';
import 'package:aanda/src/features/settlement/domain/entities/deposit.dart';

class RecordDepositSheet extends StatefulWidget {
  const RecordDepositSheet({
    super.key,
    required this.houseId,
    this.existingDeposit,
    this.onDepositSaved,
  });

  final String houseId;
  final Deposit? existingDeposit;
  final VoidCallback? onDepositSaved;

  static Future<bool?> show({
    required BuildContext context,
    required String houseId,
    Deposit? existingDeposit,
    VoidCallback? onDepositSaved,
  }) {
    final colors = AppColors.context(context);
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => RecordDepositSheet(
        houseId: houseId,
        existingDeposit: existingDeposit,
        onDepositSaved: onDepositSaved,
      ),
    );
  }

  @override
  State<RecordDepositSheet> createState() => _RecordDepositSheetState();
}

class _RecordDepositSheetState extends State<RecordDepositSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  List<HouseMember> _members = [];
  String? _selectedUserId;
  late DateTime _selectedDate;
  late DepositType _selectedType;
  bool _isLoadingMembers = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _errorMessage;

  bool get _isEditing => widget.existingDeposit != null;
  bool get _isSettled => widget.existingDeposit?.isSettled ?? false;

  @override
  void initState() {
    super.initState();
    final dep = widget.existingDeposit;
    _amountController = TextEditingController(
      text: dep != null ? dep.amount.toStringAsFixed(dep.amount.truncateToDouble() == dep.amount ? 0 : 2) : '',
    );
    _noteController = TextEditingController(text: dep?.note ?? '');
    _selectedDate = dep?.depositDate ?? DateTime.now();
    _selectedType = dep?.depositType ?? DepositType.advance;
    _selectedUserId = dep?.userId;

    _loadMembers();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final membersUsecase = context.read<GetHouseMembers>();
      final result = await membersUsecase(widget.houseId);
      if (mounted) {
        if (result.success && result.data != null) {
          final members = result.data!;
          final currentUid = Supabase.instance.client.auth.currentUser?.id;
          setState(() {
            _members = members;
            _isLoadingMembers = false;
            if (_selectedUserId == null) {
              // Default to logged-in user if member of house, otherwise first member
              final hasMe = members.any((m) => m.userId == currentUid);
              _selectedUserId = hasMe ? currentUid : (members.isNotEmpty ? members.first.userId : currentUid);
            }
          });
        } else {
          setState(() {
            _isLoadingMembers = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingMembers = false);
      }
    }
  }

  Future<void> _pickDate() async {
    if (_isSettled) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleSave() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount greater than 0.');
      return;
    }

    final userId = _selectedUserId ?? Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      setState(() => _errorMessage = 'Please select a member for this deposit.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final datasource = context.read<DepositRemoteDatasource>();

      if (_isEditing) {
        await datasource.updateDeposit(
          depositId: widget.existingDeposit!.id,
          userId: userId,
          amount: amount,
          depositType: _selectedType,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          depositDate: _selectedDate,
        );
      } else {
        await datasource.recordDeposit(
          houseId: widget.houseId,
          userId: userId,
          amount: amount,
          depositType: _selectedType,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          depositDate: _selectedDate,
        );
      }

      if (mounted) {
        context.read<HouseContextCubit>().notifyCostUpdated();
        widget.onDepositSaved?.call();
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Deposit updated successfully'
                  : 'Deposit of ৳${amount.toStringAsFixed(0)} recorded successfully',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to save deposit: ${e.toString().replaceAll('Exception:', '').trim()}';
        });
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = AppColors.context(ctx);
        return AlertDialog(
          backgroundColor: colors.surfaceColor,
          title: Text(
            'Delete Deposit?',
            style: AppTextStyles.sectionHeader.copyWith(color: colors.textColor),
          ),
          content: Text(
            'Are you sure you want to delete this deposit record? This action cannot be undone.',
            style: AppTextStyles.rowSubtitle.copyWith(color: colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancel', style: TextStyle(color: colors.grey)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.unsettledColor,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      final datasource = context.read<DepositRemoteDatasource>();
      await datasource.deleteDeposit(widget.existingDeposit!.id);

      if (mounted) {
        context.read<HouseContextCubit>().notifyCostUpdated();
        widget.onDepositSaved?.call();
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deposit record deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _errorMessage = 'Failed to delete deposit: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: colors.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing ? 'Edit Deposit' : 'Record Deposit',
                        style: AppTextStyles.sectionHeader.copyWith(
                          fontSize: 20,
                          color: colors.textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isEditing
                            ? 'Update details of this deposit entry'
                            : 'Log member advance or cash fund',
                        style: AppTextStyles.rowSubtitle.copyWith(
                          color: colors.grey,
                        ),
                      ),
                    ],
                  ),
                  if (_isSettled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colors.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 13, color: colors.primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            'Settled • Locked',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              if (_isSettled)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.softGrey,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: colors.grey),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This deposit has been reconciled in a finalized settlement. It cannot be modified or deleted.',
                          style: TextStyle(fontSize: 13, color: colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.unsettledColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.unsettledColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, size: 18, color: colors.unsettledColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.unsettledColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── 1. Select Member ───────────────────────────────────────────
              Text(
                'MEMBER',
                style: AppTextStyles.rowSubtitle.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              if (_isLoadingMembers)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator.adaptive(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(colors.textColor),
                      ),
                    ),
                  ),
                )
              else if (_members.isNotEmpty)
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _members.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final member = _members[idx];
                      final isSelected = member.userId == _selectedUserId;
                      return ChoiceChip(
                        avatar: CircleAvatar(
                          radius: 12,
                          backgroundColor: isSelected ? colors.invertTextColor : colors.softGrey,
                          backgroundImage: member.avatarUrl != null
                              ? NetworkImage(member.avatarUrl!)
                              : null,
                          child: member.avatarUrl == null
                              ? Text(
                                  member.displayName.isNotEmpty
                                      ? member.displayName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? colors.textColor : colors.textColor,
                                  ),
                                )
                              : null,
                        ),
                        label: Text(member.displayName),
                        selected: isSelected,
                        selectedColor: colors.textColor,
                        backgroundColor: colors.softGrey,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? colors.invertTextColor : colors.textColor,
                        ),
                        side: BorderSide(
                          color: isSelected ? colors.textColor : colors.dividerColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        onSelected: _isSettled
                            ? null
                            : (selected) {
                                if (selected) {
                                  setState(() => _selectedUserId = member.userId);
                                }
                              },
                      );
                    },
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.softGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'No members found for this house.',
                    style: TextStyle(fontSize: 13, color: colors.grey),
                  ),
                ),
              const SizedBox(height: 18),

              // ── 2. Amount Input ───────────────────────────────────────────
              Text(
                'AMOUNT',
                style: AppTextStyles.rowSubtitle.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: colors.softGrey,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.dividerColor),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '৳',
                      style: AppTextStyles.amountLarge.copyWith(
                        fontSize: 24,
                        color: colors.textColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        enabled: !_isSettled && !_isSaving,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: AppTextStyles.amountLarge.copyWith(
                          fontSize: 24,
                          color: colors.textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: AppTextStyles.amountLarge.copyWith(
                            fontSize: 24,
                            color: colors.grey.withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ── 3. Date & Type Row ─────────────────────────────────────────
              Row(
                children: [
                  // Date Picker Field
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DATE',
                          style: AppTextStyles.rowSubtitle.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: colors.softGrey,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colors.dividerColor),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 16, color: colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    DateFormat('d MMM yyyy').format(_selectedDate),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Deposit Type Selector
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TYPE',
                          style: AppTextStyles.rowSubtitle.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.softGrey,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: colors.dividerColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<DepositType>(
                              value: _selectedType,
                              isExpanded: true,
                              icon: Icon(Icons.arrow_drop_down_rounded, color: colors.textColor),
                              dropdownColor: colors.surfaceColor,
                              onChanged: _isSettled || _isSaving
                                  ? null
                                  : (type) {
                                      if (type != null) {
                                        setState(() => _selectedType = type);
                                      }
                                    },
                              items: [
                                DropdownMenuItem(
                                  value: DepositType.advance,
                                  child: Text(
                                    'Advance Fund',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textColor,
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: DepositType.costPayment,
                                  child: Text(
                                    'Cost Payment',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── 4. Optional Note ──────────────────────────────────────────
              Text(
                'NOTE / REFERENCE (OPTIONAL)',
                style: AppTextStyles.rowSubtitle.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: colors.softGrey,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.dividerColor),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _noteController,
                  enabled: !_isSettled && !_isSaving,
                  style: TextStyle(fontSize: 14, color: colors.textColor),
                  decoration: InputDecoration(
                    hintText: 'e.g. Cash given to manager, bKash: TrxID...',
                    hintStyle: TextStyle(fontSize: 13, color: colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Actions ───────────────────────────────────────────────────
              if (!_isSettled) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.textColor,
                          foregroundColor: colors.invertTextColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _isSaving || _isDeleting ? null : _handleSave,
                        child: _isSaving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(colors.invertTextColor),
                                ),
                              )
                            : Text(
                                _isEditing ? 'Save Changes' : 'Record Deposit',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                      ),
                    ),
                    if (_isEditing) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.unsettledColor.withValues(alpha: 0.12),
                            foregroundColor: colors.unsettledColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _isSaving || _isDeleting ? null : _handleDelete,
                          icon: _isDeleting
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(colors.unsettledColor),
                                  ),
                                )
                              : const Icon(Icons.delete_outline_rounded, size: 18),
                          label: const Text(
                            'Delete',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
