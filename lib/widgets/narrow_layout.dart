import 'package:flutter/material.dart';

class NarrowLayout extends StatelessWidget {
  final Widget child;

  const NarrowLayout({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: child,
      ),
    );
  }
}