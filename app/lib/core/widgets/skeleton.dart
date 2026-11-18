import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A bright light band that sweeps across every skeleton placeholder under it.
/// The gradient is masked onto the opaque box pixels only, so the gaps between
/// placeholders stay transparent.
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  static const _base = AppColors.surfaceLight;
  static final _highlight = Color.lerp(_base, Colors.white, 0.14)!;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [_base, _base, _highlight, _base, _base],
          stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
          transform: _SlideTransform(_controller.value),
        ).createShader(bounds),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Slides the shimmer gradient from fully off the left edge to fully off the
/// right as [progress] goes 0 → 1.
class _SlideTransform extends GradientTransform {
  const _SlideTransform(this.progress);

  final double progress;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final dx = bounds.width * (progress * 2 - 1);
    return Matrix4.translationValues(dx, 0, 0);
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height, this.radius = 8});

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Placeholder for a poster grid while the first database read resolves.
class PosterGridSkeleton extends StatelessWidget {
  const PosterGridSkeleton({super.key, required this.gutter});

  final double gutter;

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 32),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 160,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 2 / 3,
        ),
        itemCount: 18,
        itemBuilder: (_, _) => const SkeletonBox(),
      ),
    );
  }
}

/// Full details-page placeholder — poster block plus title, meta, buttons and
/// plot lines — shown while the catalog row and metadata resolve.
class DetailsSkeleton extends StatelessWidget {
  const DetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return SkeletonPulse(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 20 : 48,
            20,
            compact ? 20 : 48,
            40,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!compact) ...[
                const SkeletonBox(width: 220, height: 330),
                const SizedBox(width: 32),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: compact ? 200 : 320, height: 34),
                    const SizedBox(height: 14),
                    const SkeletonBox(width: 180, height: 16),
                    const SizedBox(height: 24),
                    Row(
                      children: const [
                        SkeletonBox(width: 150, height: 52),
                        SizedBox(width: 12),
                        SkeletonBox(width: 130, height: 52),
                      ],
                    ),
                    const SizedBox(height: 26),
                    const SkeletonBox(width: double.infinity, height: 13),
                    const SizedBox(height: 8),
                    const SkeletonBox(width: double.infinity, height: 13),
                    const SizedBox(height: 8),
                    const SkeletonBox(width: 260, height: 13),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A few text lines standing in for the plot/credits block while the metadata
/// fetch is in flight.
class DetailsTextSkeleton extends StatelessWidget {
  const DetailsTextSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: SkeletonPulse(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(width: double.infinity, height: 13),
            SizedBox(height: 8),
            SkeletonBox(width: double.infinity, height: 13),
            SizedBox(height: 8),
            SkeletonBox(width: 260, height: 13),
            SizedBox(height: 16),
            SkeletonBox(width: 180, height: 12),
          ],
        ),
      ),
    );
  }
}

/// Season chips plus a few episode rows, mirroring the series episode list
/// while its metadata loads.
class EpisodesSkeleton extends StatelessWidget {
  const EpisodesSkeleton({super.key, this.rows = 4});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 90, height: 12),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              SkeletonBox(width: 96, height: 34, radius: 17),
              SkeletonBox(width: 96, height: 34, radius: 17),
              SkeletonBox(width: 96, height: 34, radius: 17),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < rows; i++) ...[
            Row(
              children: [
                const SkeletonBox(width: 16, height: 16),
                const SizedBox(width: 16),
                const SkeletonBox(width: 128, height: 72),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(width: 160, height: 13),
                      SizedBox(height: 8),
                      SkeletonBox(width: double.infinity, height: 11),
                      SizedBox(height: 6),
                      SkeletonBox(width: 220, height: 11),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

/// Icon + title (+ optional message) for empty lists, replacing bare text.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
  });

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.textSecondary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Channel logos and programme labels while the first Live TV read resolves.
class ChannelListSkeleton extends StatelessWidget {
  const ChannelListSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading channels',
    child: ExcludeSemantics(
      child: SkeletonPulse(
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: 8,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (_, _) => const Row(
            children: [
              SkeletonBox(width: 48, height: 48),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FractionallySizedBox(
                      widthFactor: .7,
                      child: SkeletonBox(height: 14),
                    ),
                    SizedBox(height: 10),
                    FractionallySizedBox(
                      widthFactor: .45,
                      child: SkeletonBox(height: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
