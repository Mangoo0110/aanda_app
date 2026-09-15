import 'package:flutter/material.dart';
import 'package:aanda/src/features/auth/presentation/widgets/auth_header.dart';

class AuthPageFrame extends StatelessWidget {
  const AuthPageFrame({
    super.key,
    required this.children,
    this.headerTitle,
    this.onBackPressed,
    this.bottomChild,
    this.maxWidth = 340,
    this.topSpacing = 60,
  });

  final List<Widget> children;
  final String? headerTitle;
  final VoidCallback? onBackPressed;
  final Widget? bottomChild;
  final double maxWidth;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      mainAxisAlignment: bottomChild == null
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.spaceBetween,
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxWidth),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(height: topSpacing),
                                ...children,
                              ],
                            ),
                          ),
                        ),
                        if (bottomChild != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: maxWidth),
                                child: bottomChild,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (headerTitle != null)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: AuthHeader(
                  title: headerTitle!,
                  onBackPressed: onBackPressed,
                ),
              ),
          ],
        );
      },
    );
  }
}
