import 'package:flutter/material.dart';
import 'package:aanda/src/core/shared/widget/app_back_button.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, this.onBackPressed});

  final String title;
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          AppBackButton(
            margin: const EdgeInsets.only(left: 16, right: 12),
            onPressed: onBackPressed,
          ),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
