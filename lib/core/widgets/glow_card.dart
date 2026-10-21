import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class GlowCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? glowColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool isSelected;
  final Gradient? customGradient;

  const GlowCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.glowColor,
    this.borderColor,
    this.padding,
    this.margin,
    this.borderRadius = 18,
    this.isSelected = false,
    this.customGradient,
  });

  @override
  State<GlowCard> createState() => _GlowCardState();
}

class _GlowCardState extends State<GlowCard> with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null) _pressController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onTap != null) _pressController.reverse();
  }

  void _onTapCancel() {
    if (widget.onTap != null) _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final activeGlow = widget.isSelected
        ? (widget.glowColor ?? AppColors.mafiaGlow)
        : (widget.glowColor ?? Colors.transparent);

    final activeBorder = widget.isSelected
        ? (widget.glowColor ?? AppColors.mafiaGlow)
        : (widget.borderColor ?? AppColors.surfaceBorder);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: Container(
        margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: widget.isSelected || widget.glowColor != null
              ? [
                  BoxShadow(
                    color: activeGlow.withValues(alpha: widget.isSelected ? 0.28 : 0.15),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            splashColor: (widget.glowColor ?? AppColors.mafia).withValues(alpha: 0.12),
            highlightColor: Colors.transparent,
            child: Ink(
              padding: widget.padding ?? const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                gradient: widget.customGradient ??
                    LinearGradient(
                      colors: [
                        AppColors.surfaceElevated.withValues(alpha: 0.9),
                        AppColors.surface.withValues(alpha: 0.95),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                border: Border.all(
                  color: activeBorder,
                  width: widget.isSelected ? 1.8 : 1.0,
                ),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
