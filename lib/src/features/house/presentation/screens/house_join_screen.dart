import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/house/presentation/bloc/house_join/house_join_bloc.dart';

class HouseJoinScreen extends StatefulWidget {
  const HouseJoinScreen({super.key});

  @override
  State<HouseJoinScreen> createState() => _HouseJoinScreenState();
}

class _HouseJoinScreenState extends State<HouseJoinScreen> {
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return BlocConsumer<HouseJoinBloc, HouseJoinState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == HouseJoinStatus.success) {
          context.pop();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colors.appBackgroundColor,
          appBar: AppBar(
            backgroundColor: colors.appBackgroundColor,
            title: Text(
              'Join House',
              style: TextStyle(color: colors.textColor),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'Enter the 8-character invite code shared by your housemate.',
                    style: TextStyle(color: colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _codeCtrl,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.characters,
                    autofocus: true,
                    onChanged: (v) => context
                        .read<HouseJoinBloc>()
                        .add(HouseJoinCodeChanged(v)),
                    onSubmitted: (_) => _submit(context, state),
                    decoration: const InputDecoration(
                      labelText: 'Invite Code',
                      hintText: 'ABCD1234',
                    ),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage!,
                      style: TextStyle(color: colors.errorColor, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: state.isSubmitting
                        ? null
                        : () => _submit(context, state),
                    child: state.isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Join House'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _submit(BuildContext context, HouseJoinState state) {
    if (state.isSubmitting) return;
    context.read<HouseJoinBloc>().add(HouseJoinSubmitted());
  }
}
