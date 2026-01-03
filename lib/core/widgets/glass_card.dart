import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;

  const GlassCard({super.key, required this.child, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glassWhite,
            borderRadius: borderRadius ?? BorderRadius.circular(24),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}
