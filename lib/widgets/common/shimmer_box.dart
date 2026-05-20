import 'package:flutter/material.dart';

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1 + (_controller.value * 2), 0),
              end: Alignment(1 + (_controller.value * 2), 0),
              colors: isDark
                  ? [const Color(0xFF2C2C2C), const Color(0xFF3C3C3C), const Color(0xFF2C2C2C)]
                  : [const Color(0xFFE6E6E6), const Color(0xFFF5F5F5), const Color(0xFFE6E6E6)],
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerGridItemState extends State<_ShimmerGridItem> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment(-1 + (_controller.value * 2), 0),
                  end: Alignment(1 + (_controller.value * 2), 0),
                  colors: isDark
                      ? [const Color(0xFF2C2C2C), const Color(0xFF3C3C3C), const Color(0xFF2C2C2C)]
                      : [const Color(0xFFE6E6E6), const Color(0xFFF5F5F5), const Color(0xFFE6E6E6)],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => Container(
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(
                begin: Alignment(-1 + (_controller.value * 2), 0),
                end: Alignment(1 + (_controller.value * 2), 0),
                colors: isDark
                    ? [const Color(0xFF2C2C2C), const Color(0xFF3C3C3C), const Color(0xFF2C2C2C)]
                    : [const Color(0xFFE6E6E6), const Color(0xFFF5F5F5), const Color(0xFFE6E6E6)],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => Container(
            height: 10,
            width: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(
                begin: Alignment(-1 + (_controller.value * 2), 0),
                end: Alignment(1 + (_controller.value * 2), 0),
                colors: isDark
                    ? [const Color(0xFF2C2C2C), const Color(0xFF3C3C3C), const Color(0xFF2C2C2C)]
                    : [const Color(0xFFE6E6E6), const Color(0xFFF5F5F5), const Color(0xFFE6E6E6)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShimmerGridItem extends StatefulWidget {
  const _ShimmerGridItem();

  @override
  State<_ShimmerGridItem> createState() => _ShimmerGridItemState();
}

class ShimmerGridItem extends StatelessWidget {
  const ShimmerGridItem();

  @override
  Widget build(BuildContext context) => const _ShimmerGridItem();
}

class _ShimmerListItemState extends State<_ShimmerListItem> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final h = widget.height;
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Row(
        children: [
          Container(
            width: h,
            height: h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: LinearGradient(
                begin: Alignment(-1 + (_controller.value * 2), 0),
                end: Alignment(1 + (_controller.value * 2), 0),
                colors: isDark
                    ? [const Color(0xFF2C2C2C), const Color(0xFF3C3C3C), const Color(0xFF2C2C2C)]
                    : [const Color(0xFFE6E6E6), const Color(0xFFF5F5F5), const Color(0xFFE6E6E6)],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment(-1 + (_controller.value * 2), 0),
                      end: Alignment(1 + (_controller.value * 2), 0),
                      colors: isDark
                          ? [const Color(0xFF2C2C2C), const Color(0xFF3C3C3C), const Color(0xFF2C2C2C)]
                          : [const Color(0xFFE6E6E6), const Color(0xFFF5F5F5), const Color(0xFFE6E6E6)],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(
                      begin: Alignment(-1 + (_controller.value * 2), 0),
                      end: Alignment(1 + (_controller.value * 2), 0),
                      colors: isDark
                          ? [const Color(0xFF2C2C2C), const Color(0xFF3C3C3C), const Color(0xFF2C2C2C)]
                          : [const Color(0xFFE6E6E6), const Color(0xFFF5F5F5), const Color(0xFFE6E6E6)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerListItem extends StatefulWidget {
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const _ShimmerListItem({this.height = 80, this.borderRadius = 12, this.margin});

  @override
  State<_ShimmerListItem> createState() => _ShimmerListItemState();
}

class ShimmerListItem extends StatelessWidget {
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerListItem({this.height = 80, this.borderRadius = 12, this.margin});

  @override
  Widget build(BuildContext context) => _ShimmerListItem(height: height, borderRadius: borderRadius, margin: margin);
}

class ShimmerLoadingGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double padding;

  const ShimmerLoadingGrid({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.75,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
    this.padding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => const ShimmerGridItem(),
      ),
    );
  }
}
