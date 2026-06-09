import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';

class HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  const HoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin,
    this.color,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: widget.margin,
        child: Card(
          elevation: _hovered ? AppDimensions.cardElevationHover : AppDimensions.cardElevation,
          color: widget.color,
          child: widget.onTap != null
              ? InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  child: widget.child,
                )
              : widget.child,
        ),
      ),
    );
  }
}
