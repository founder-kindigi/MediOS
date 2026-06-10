import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class ShimmerSkeleton extends StatefulWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final double? borderRadius;

  const ShimmerSkeleton({
    super.key,
    this.child,
    this.width,
    this.height,
    this.borderRadius,
  });

  factory ShimmerSkeleton.circle({required double radius}) {
    return ShimmerSkeleton(
      width: radius * 2,
      height: radius * 2,
      borderRadius: radius,
    );
  }

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shimmerChild = widget.child ?? Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: widget.borderRadius != null
            ? BorderRadius.circular(widget.borderRadius!)
            : BorderRadius.circular(AppDimensions.radiusSm),
      ),
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.shimmerBase,
                AppColors.shimmerHighlight,
                AppColors.shimmerBase,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform:
                  GradientSliding(_controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: shimmerChild,
    );
  }
}

class GradientSliding extends GradientTransform {
  final double value;
  const GradientSliding(this.value);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (value * 2 - 1), 0, 0);
  }
}

class ShimmerBlock extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  const ShimmerBlock({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = AppDimensions.radiusSm,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  const ShimmerList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.md),
          child: ShimmerSkeleton(
            child: Container(
              height: itemHeight,
              decoration: BoxDecoration(
                color: AppColors.shimmerBase,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Row(
                children: [
                  const SizedBox(width: AppDimensions.lg),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.5,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.3,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ShimmerGrid extends StatelessWidget {
  final int crossAxisCount;
  final int itemCount;
  const ShimmerGrid({
    super.key,
    this.crossAxisCount = 2,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppDimensions.md,
        mainAxisSpacing: AppDimensions.md,
        childAspectRatio: 1.5,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return ShimmerSkeleton(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          ),
        );
      },
    );
  }
}
