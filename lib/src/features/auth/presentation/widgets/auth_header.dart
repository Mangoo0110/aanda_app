import 'package:flutter/material.dart';

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
          IconButton(
            tooltip: 'Back',
            onPressed: onBackPressed,
            icon: const Icon(Icons.arrow_back_rounded),
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
