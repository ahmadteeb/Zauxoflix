import 'package:flutter/material.dart';

import '../../data/live/live_directory.dart';

const sportsMint = Color(0xFFAAE6D1);

class SportsGroupHeading extends StatelessWidget {
  const SportsGroupHeading({
    required this.group,
    required this.count,
    required this.featured,
    super.key,
  });

  final LiveSportsGroup group;
  final int count;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final channelCount = count == 1 ? '1 channel' : '$count channels';
    final title = Text(
      group.label,
      style: TextStyle(
        fontSize: featured ? 27 : 20,
        fontWeight: FontWeight.w800,
        height: 1.10,
        letterSpacing: featured ? -.8 : -.4,
        color: Colors.white,
      ),
    );
    final total = Text(
      channelCount,
      style: TextStyle(
        color: featured ? sportsMint : const Color(0xFFBCC8C5),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
    return Semantics(
      header: true,
      child: Padding(
        padding: EdgeInsets.only(top: featured ? 1 : 18, bottom: 4),
        child: featured
            ? ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xED193A37), Color(0xE3222C34)],
                    ),
                  ),
                  child: Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: [
                      PositionedDirectional(
                        end: -14,
                        top: 0,
                        bottom: 0,
                        width: 120,
                        child: CustomPaint(
                          painter: _PitchMarkings(
                            group != LiveSportsGroup.other,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          16,
                          16,
                          34,
                          15,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [title, const SizedBox(height: 4), total],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 8, 3),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [title, total],
                ),
              ),
      ),
    );
  }
}

// Part of a pitch, cropped into the scoreboard like a football broadcast graphic.
class _PitchMarkings extends CustomPainter {
  const _PitchMarkings(this.football);
  final bool football;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0x46ACE8D2);
    canvas.save();
    canvas.translate(size.width * .60, size.height * .50);
    canvas.rotate(-.28);
    final half = size.height * .64;
    if (football) {
      final box = Rect.fromLTRB(-half, -half, half, half);
      canvas.drawRect(box, paint);
      canvas.drawLine(Offset(-half, 0), Offset(half, 0), paint);
      canvas.drawCircle(Offset.zero, half * .39, paint);
      canvas.drawRect(
        Rect.fromLTRB(-half * .46, -half, half * .46, -half * .72),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTRB(-half * .46, half * .72, half * .46, half),
        paint,
      );
    } else {
      for (final inset in [0.0, 9.0, 18.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              -half + inset,
              -half + inset,
              2.7 * half - inset * 2,
              2 * half - inset * 2,
            ),
            Radius.circular(half - inset),
          ),
          paint,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PitchMarkings oldDelegate) =>
      football != oldDelegate.football;
}
