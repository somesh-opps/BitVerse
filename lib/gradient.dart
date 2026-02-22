import 'package:flutter/material.dart';

/// A simplified background widget that provides a pure dark canvas.
/// Replaces the previous complex generative mesh as requested by the user.
class AuroraGradient extends StatelessWidget {
  final Widget? child;
  const AuroraGradient({Key? key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF000000), // Pure dark background (Black)
      child: child,
    );
  }
}
