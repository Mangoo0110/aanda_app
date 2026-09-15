import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/core/theme/app_colors.dart';

class HouseCreateScreen extends StatefulWidget {
  const HouseCreateScreen({super.key});

  @override
  State<HouseCreateScreen> createState() => _HouseCreateScreenState();
}

class _HouseCreateScreenState extends State<HouseCreateScreen> {
  final _nameController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a house or group name';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User is not signed in.');
      }

      final houseData = await supabase.from('houses').insert({
        'name': name,
        'created_by': user.id,
        'currency': 'BDT',
      }).select().single();

      await supabase.from('house_members').insert({
        'house_id': houseData['id'],
        'user_id': user.id,
        'role': 'admin',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('House "$name" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Failed to create house: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Scaffold(
      backgroundColor: colors.appBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Create Shared House',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: colors.textColor,
          ),
        ),
        backgroundColor: colors.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.iconColor),
          onPressed: () => context.pop(),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Create House',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.home_work_rounded,
                  size: 38,
                  color: Colors.teal,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Start a Shared House',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: colors.textColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Create a space for your roommates, flatmates, or family to track shared costs and split expenses.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.grey,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'House / Group Name',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              focusNode: _focusNode,
              autofocus: true,
              style: TextStyle(
                color: colors.textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.home_outlined,
                  color: colors.iconColor,
                ),
                hintText: 'e.g. Bachelor Pad, Flat 4B, Dhanmondi Mess',
                hintStyle: TextStyle(
                  color: colors.hintColor,
                  fontWeight: FontWeight.normal,
                ),
                filled: true,
                fillColor: colors.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colors.borderColor.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colors.primaryColor,
                    width: 1.5,
                  ),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: colors.errorColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.tileColor.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: colors.grey,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You will automatically be set as the house admin and can invite roommates later.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.grey,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
