import 'dart:ui';
import 'package:flutter/material.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final BorderRadius? customBorderRadius;
  final EdgeInsetsGeometry padding;

  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = 32.0,
    this.customBorderRadius,
    this.padding = const EdgeInsets.all(32.0),
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius =
        customBorderRadius ?? BorderRadius.circular(borderRadius);
    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.4),
            borderRadius: effectiveBorderRadius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF914B34).withValues(alpha: 0.08),
                blurRadius: 80,
                offset: const Offset(0, 30),
              ),
              // Inner shadow simulation could be done via another layer, but simple box shadow suffices for the outer part
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
