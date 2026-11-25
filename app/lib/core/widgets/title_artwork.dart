import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/media_item.dart';

enum ArtworkKind {
  movie,
  series,
  episode,
  live;

  static ArtworkKind forMedia(MediaType? type) => switch (type) {
    MediaType.live => live,
    MediaType.series => series,
    MediaType.movie || null => movie,
  };
}

/// An offline cover. A parent with a title over the image supplies the lettering
/// itself, so crossfades, focus previews and rank overlays keep their hierarchy.
class TitleArtwork extends StatelessWidget {
  const TitleArtwork({
    super.key,
    required this.title,
    required this.kind,
    this.hasCaption = false,
    this.emptyIcon,
  });

  final String title;
  final ArtworkKind kind;
  final bool hasCaption;
  final IconData? emptyIcon;

  @override
  Widget build(BuildContext context) {
    final name = title.trim();
    // Keep the same edition across sessions, including on the web.
    final seed = name.toLowerCase().runes.fold<int>(
      kind.index + 1,
      (hash, rune) => (hash * 31 + rune) & 0x3fffffff,
    );
    return ClipRect(
      child: CustomPaint(
        painter: _CoverPainter(kind, seed),
        child: hasCaption
            ? const SizedBox.expand()
            : Stack(
                children: [
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, bounds) {
                        final short = bounds.biggest.shortestSide;
                        final landscape =
                            bounds.maxWidth > bounds.maxHeight * 1.15;
                        final tiny = short < 46;
                        final inset = (short * .09).clamp(2.0, 24.0);
                        final fontSize = (short * (landscape ? .30 : .19))
                            .clamp(8.0, 48.0);
                        return Padding(
                          padding: EdgeInsets.all(inset),
                          child: Align(
                            alignment: AlignmentDirectional.bottomStart,
                            child: name.isEmpty
                                ? Icon(
                                    emptyIcon ?? Icons.movie_outlined,
                                    size: (short * .28).clamp(10.0, 44.0),
                                    color: Colors.white70,
                                  )
                                : _lettering(
                                    context,
                                    name,
                                    fontSize,
                                    bounds.deflate(EdgeInsets.all(inset)),
                                    tiny || landscape ? 2 : 4,
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // A long word should fit the cover as a word. Keep the full semantic label
  // when even the smallest legible type cannot fit a very small channel tile.
  Widget _lettering(
    BuildContext context,
    String name,
    double size,
    BoxConstraints space,
    int lines,
  ) {
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final base = DefaultTextStyle.of(context).style.copyWith(
      color: const Color(0xfffffaf4),
      fontWeight: FontWeight.w800,
      height: 1.1,
      shadows: const [Shadow(blurRadius: 4, color: Colors.black54)],
    );
    final measure = TextPainter(
      textDirection: direction,
      textScaler: scaler,
      maxLines: lines,
      ellipsis: '…',
    );
    final minimum = math.max(7.0, size * .50);
    final displayStyle = base.copyWith(
      fontSize: size,
      letterSpacing: -.025 * size,
    );
    var widestWord = 0.0;
    for (final word in name.split(RegExp(r'\s+'))) {
      measure.text = TextSpan(text: word, style: displayStyle);
      measure.layout();
      widestWord = math.max(widestWord, measure.width);
    }
    if (widestWord > space.maxWidth) {
      size = math.max(minimum, size * space.maxWidth / widestWord * .99);
    }
    late TextSpan span;
    while (true) {
      span = TextSpan(
        text: name,
        style: base.copyWith(fontSize: size, letterSpacing: -.025 * size),
      );
      measure.text = span;
      measure.layout(maxWidth: space.maxWidth);
      if (size <= minimum ||
          (!measure.didExceedMaxLines && measure.height <= space.maxHeight)) {
        break;
      }
      size = math.max(minimum, size * .90);
    }
    measure.dispose();
    return RichText(
      text: span,
      textDirection: direction,
      textScaler: scaler,
      maxLines: lines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

typedef _Inks = ({Color paper, Color mid, Color light});

const _inks = <_Inks>[
  (paper: Color(0xff211526), mid: Color(0xffa84865), light: Color(0xffffcd99)),
  (paper: Color(0xff0b2128), mid: Color(0xff227577), light: Color(0xffa7f4d2)),
  (paper: Color(0xff141c38), mid: Color(0xff5268b2), light: Color(0xffc6ddff)),
  (paper: Color(0xff2b1b22), mid: Color(0xffae5b40), light: Color(0xffffd391)),
  (paper: Color(0xff21192e), mid: Color(0xff71519a), light: Color(0xffe7c2fa)),
];

class _CoverPainter extends CustomPainter {
  const _CoverPainter(this.kind, this.seed);
  final ArtworkKind kind;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final ink = _inks[seed % _inks.length];
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color.lerp(ink.mid, ink.paper, .18)!, ink.paper],
        ).createShader(rect),
    );

    // Work in cover-relative units. Keep the illustration above the title on
    // posters and towards the right edge on landscape stills and backdrops.
    final unit = math.max(size.shortestSide, size.longestSide * .56);
    final variation = ((seed ~/ 5) % 17) / 16;
    canvas.save();
    canvas.translate(
      size.width * (.64 + .13 * variation),
      size.height * (size.aspectRatio > 1 ? .36 : .32),
    );
    canvas.scale(unit);
    final fill = Paint()..isAntiAlias = true;
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .004;
    switch (kind) {
      case ArtworkKind.movie:
        // A striped sun cut by a sweeping beam of projector light.
        final disc = Rect.fromCircle(center: Offset.zero, radius: .30);
        canvas.save();
        canvas.rotate(-.16 - variation * .26);
        canvas.clipPath(Path()..addOval(disc));
        fill.shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ink.light, ink.mid],
        ).createShader(disc);
        canvas.drawRect(Rect.fromLTRB(-.32, -.32, .32, -.014), fill);
        for (var i = 0; i < 8; i++) {
          final top = -.003 + i * .041;
          canvas.drawRect(
            Rect.fromLTWH(-.32, top, .64, .031 - i * .0027),
            fill,
          );
        }
        canvas.restore();
        fill.shader = null;
        final beam = Path()
          ..moveTo(-1.65, .92)
          ..lineTo(1.4, -.29)
          ..lineTo(1.4, .05)
          ..close();
        canvas.drawPath(beam, fill..color = ink.light.withValues(alpha: .18));
        canvas.drawLine(
          const Offset(-1.65, .92),
          const Offset(1.4, -.29),
          pen..color = ink.light.withValues(alpha: .54),
        );
      case ArtworkKind.series:
        // A sequence of translucent glass frames, backlit along their edges.
        canvas.rotate(-.32 - variation * .13);
        for (var i = 0; i < 5; i++) {
          final panel = Rect.fromLTWH(
            -.57 + i * .115,
            -.31 - i * .034,
            .46,
            .74,
          );
          final frame = RRect.fromRectAndRadius(
            panel,
            const Radius.circular(.034),
          );
          fill.shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(ink.mid, ink.light, .14 + i * .1)!, ink.paper],
          ).createShader(panel);
          canvas.drawRRect(frame, fill);
          canvas.drawRRect(
            frame,
            pen..color = ink.light.withValues(alpha: .68),
          );
        }
      case ArtworkKind.episode:
        canvas.drawCircle(
          const Offset(.06, -.05),
          .15,
          fill..color = ink.light,
        );
        for (var i = 0; i < 3; i++) {
          final y = -.03 + i * .19;
          final ridge = Path()
            ..moveTo(-1.8, y + .21)
            ..lineTo(-.83, y + .1)
            ..lineTo(-.46 + i * .13, y - .13)
            ..lineTo(-.19 + i * .15, y + .07)
            ..lineTo(.31 + i * .14, y - .20)
            ..lineTo(.78, y + .04)
            ..lineTo(1.8, y - .22)
            ..lineTo(1.8, 1.6)
            ..lineTo(-1.8, 1.6)
            ..close();
          canvas.drawPath(
            ridge,
            fill..color = Color.lerp(ink.mid, ink.paper, i * .34)!,
          );
          canvas.drawPath(
            ridge,
            pen..color = ink.light.withValues(alpha: .55 - i * .16),
          );
        }
      case ArtworkKind.live:
        // Broadcast rings open towards the edge like a station ident.
        canvas.rotate(-.32 + variation * .14);
        for (var i = 0; i < 6; i++) {
          final ring = Rect.fromCircle(
            center: Offset.zero,
            radius: .135 + i * .096,
          );
          pen
            ..strokeWidth = i.isEven ? .026 : .006
            ..strokeCap = StrokeCap.round
            ..shader = SweepGradient(
              colors: [ink.mid, ink.light, ink.mid],
            ).createShader(ring);
          canvas.drawArc(ring, -2.74 + i * .12, 4.56 - i * .17, false, pen);
        }
        canvas.drawCircle(Offset.zero, .057, fill..color = ink.light);
    }
    canvas.restore();
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, .4, 1],
          colors: [Colors.transparent, Colors.transparent, Color(0xb50a0a12)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_CoverPainter old) => old.kind != kind || old.seed != seed;
}
