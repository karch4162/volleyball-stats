import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Glass morphism container matching the HTML design
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderColor,
    this.backgroundColor,
    this.blurAmount = 20.0,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final double blurAmount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final container = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.glass,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? AppColors.borderLight,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: container,
      );
    }

    return container;
  }
}

/// Light glass container variant
class GlassLightContainer extends StatelessWidget {
  const GlassLightContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      backgroundColor: AppColors.glassLight,
      borderColor: AppColors.borderMedium,
      blurAmount: 12.0,
      onTap: onTap,
      child: child,
    );
  }
}

/// Accent glass container variant
class GlassAccentContainer extends StatelessWidget {
  const GlassAccentContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      backgroundColor: AppColors.glassAccent,
      borderColor: AppColors.borderAccent,
      blurAmount: 12.0,
      child: child,
    );
  }
}

