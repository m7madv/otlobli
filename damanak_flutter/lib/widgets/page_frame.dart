import 'package:flutter/material.dart';

class PageFrame extends StatelessWidget {
  const PageFrame({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 28),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: SingleChildScrollView(padding: padding, child: child),
      ),
    );
  }
}
