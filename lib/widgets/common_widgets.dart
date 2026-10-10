import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class Bouncy extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const Bouncy({super.key, required this.child, this.onTap});

  @override
  State<Bouncy> createState() => _BouncyState();
}

class _BouncyState extends State<Bouncy> {
  bool down = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: reduceMotion ? null : (_) => setState(() => down = true),
      onTapCancel: reduceMotion ? null : () => setState(() => down = false),
      onTapUp: (_) {
        if (!reduceMotion) setState(() => down = false);
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: down ? 0.975 : 1,
        duration: Duration(milliseconds: reduceMotion ? 0 : 130),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class Pop extends StatelessWidget {
  final int i;
  final Widget child;

  const Pop({super.key, this.i = 0, required this.child});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + i.clamp(0, 8) * 55),
      curve: Curves.easeOutCubic,
      builder: (_, value, content) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: content,
        ),
      ),
      child: child,
    );
  }
}

class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.surface,
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.pinkAccent, width: 2),
      boxShadow: [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: .06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    alignment: Alignment.center,
    child: Text(
      'N',
      style: GoogleFonts.cormorantGaramond(
        color: AppColors.ink,
        fontSize: size * .58,
        fontWeight: FontWeight.w700,
        height: 1,
      ),
    ),
  );
}

Widget nCard({
  required Widget child,
  VoidCallback? onTap,
  EdgeInsets pad = const EdgeInsets.all(16),
  Color? color,
}) {
  final card = Container(
    width: double.infinity,
    padding: pad,
    decoration: BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: .035),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
  return onTap == null ? card : Bouncy(onTap: onTap, child: card);
}

Widget tag(String text, Color color) => Container(
  constraints: const BoxConstraints(minHeight: 28),
  alignment: Alignment.center,
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
  decoration: BoxDecoration(
    color: color.withValues(alpha: .12),
    borderRadius: BorderRadius.circular(22),
  ),
  child: Text(
    text,
    style: GoogleFonts.plusJakartaSans(
      color: color,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
  ),
);

Widget sectionTitle(String text) => Padding(
  padding: const EdgeInsets.fromLTRB(0, 22, 0, 12),
  child: Text(
    text,
    style: GoogleFonts.cormorantGaramond(
      color: AppColors.ink,
      fontSize: 28,
      fontWeight: FontWeight.w700,
    ),
  ),
);

class CatalogArtwork extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;
  final double size;
  final Color background;

  const CatalogArtwork({
    super.key,
    required this.imageUrl,
    required this.fallbackIcon,
    this.size = 56,
    this.background = AppColors.pinkPastel,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(16),
    ),
    clipBehavior: Clip.antiAlias,
    child: imageUrl == null
        ? Icon(fallbackIcon, size: size * .44, color: AppColors.pinkText)
        : Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stackTrace) =>
                Icon(fallbackIcon, size: size * .44, color: AppColors.pinkText),
          ),
  );
}

class ProgressRing extends StatelessWidget {
  final double value;
  final String label;
  final String caption;
  final double size;

  const ProgressRing({
    super.key,
    required this.value,
    required this.label,
    required this.caption,
    this.size = 96,
  });

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
    duration: Duration(
      milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 1500,
    ),
    curve: Curves.easeOutCubic,
    builder: (_, progress, _) => SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.surface,
              color: AppColors.pinkAccent,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(caption, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ],
      ),
    ),
  );
}

class StitchLine extends StatelessWidget {
  final Animation<double> animation;
  final Color color;

  const StitchLine({
    super.key,
    required this.animation,
    this.color = AppColors.blueStrong,
  });

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (_, _) => CustomPaint(
      painter: _StitchPainter(
        offset: MediaQuery.disableAnimationsOf(context) ? 0 : animation.value,
        color: color,
      ),
      child: const SizedBox(height: 4, width: double.infinity),
    ),
  );
}

class _StitchPainter extends CustomPainter {
  final double offset;
  final Color color;

  const _StitchPainter({required this.offset, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 6.0;
    const gap = 6.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final shift = offset * (dash + gap);
    for (var x = -dash - shift; x < size.width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(x + dash * .62, size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StitchPainter oldDelegate) =>
      oldDelegate.offset != offset || oldDelegate.color != color;
}

Widget tagLine(String text) => Text(
  text,
  style: GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.muted,
  ),
);
