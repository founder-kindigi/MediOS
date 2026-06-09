import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MinimumTouchTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double minSize;

  const MinimumTouchTarget({
    super.key,
    required this.child,
    this.onTap,
    this.minSize = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: SizedBox(
        width: minSize,
        height: minSize,
        child: Center(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: child,
          ),
        ),
      ),
    );
  }
}

class TouchTargetIconButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final Color? color;
  final double iconSize;
  final double minSize;

  const TouchTargetIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.color,
    this.iconSize = 20,
    this.minSize = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox(
        width: minSize,
        height: minSize,
        child: IconButton(
          icon: Icon(icon, size: iconSize),
          onPressed: onPressed,
          color: color,
          tooltip: semanticLabel,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
      ),
    );
  }
}
