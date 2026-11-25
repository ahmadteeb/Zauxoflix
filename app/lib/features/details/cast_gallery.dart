import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/external_link.dart';
import '../../data/discovery/imdb_index.dart';
import '../../core/models/media_item.dart';
import '../../data/discovery/actor_library.dart';
import '../../data/providers.dart';
import 'actor_library_section.dart';
import 'media_navigation.dart';

class CastGallery extends StatefulWidget {
  const CastGallery({
    super.key,
    required this.title,
    required this.cast,
    required this.photos,
    this.origin,
  });

  final String title;
  final ActorOrigin? origin;
  final List<ImdbPerson> cast;
  final Map<String, String?> photos;

  @override
  State<CastGallery> createState() => _CastGalleryState();
}

class _CastGalleryState extends State<CastGallery> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final available = constraints.maxWidth;
      final gap = available < 600 ? 12.0 : 16.0;
      final target = available < 600 ? 148.0 : 184.0;
      final scaler = MediaQuery.textScalerOf(context);
      final columns =
          ((available + gap) / (target * scaler.scale(16) / 16 + gap))
              .floor()
              .clamp(1, 6);
      final width = (available - (columns - 1) * gap) / columns;
      final count = math.max(2, columns);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.cast.length > count)
                TextButton.icon(
                  onPressed: () => setState(() => expanded = !expanded),
                  icon: Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                  iconAlignment: IconAlignment.end,
                  label: Text(
                    expanded
                        ? 'Show fewer'
                        : 'Show all ${widget.cast.length} cast members',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final person in widget.cast.take(
                expanded ? widget.cast.length : count,
              ))
                _CastCard(
                  key: ValueKey(person.id),
                  person: person,
                  photo: widget.photos[person.id],
                  width: width,
                  origin: widget.origin,
                ),
            ],
          ),
        ],
      );
    },
  );
}

class _CastCard extends ConsumerWidget {
  const _CastCard({
    super.key,
    required this.person,
    required this.photo,
    required this.width,
    required this.origin,
  });
  final ImdbPerson person;
  final String? photo;
  final double width;
  final ActorOrigin? origin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameSize = width < 195 ? 18.0 : 21.0;
    final roleSize = width < 195 ? 14.0 : 16.0;
    final scaler = MediaQuery.textScalerOf(context);
    final captionSpace =
        scaler.scale(nameSize) * 2.3 + scaler.scale(roleSize) * 1.25 + 34;
    final height = math.max(
      (width * 1.23).clamp(180.0, 338.0),
      captionSpace + 76,
    );
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        clipBehavior: Clip.antiAlias,
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return const BorderSide(color: AppColors.focusRing, width: 3);
            }
            if (states.contains(WidgetState.hovered)) {
              return const BorderSide(color: Colors.white70, width: 2);
            }
            return const BorderSide(color: AppColors.outline);
          }),
        ),
        onPressed: () async {
          final selected = await showDialog<MediaItem>(
            context: context,
            builder: (_) =>
                _PersonDialog(person: person, photo: photo, origin: origin),
          );
          if (selected != null &&
              context.mounted &&
              ref.read(activeSourceProvider).value?.id == origin?.source) {
            openMediaItem(context, ref, selected);
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Portrait(person: person, photo: photo, withCaption: true),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.32, 0.60, 0.83, 1],
                  colors: [
                    Colors.transparent,
                    Color(0x330B0B0F),
                    Color(0xC70B0B0F),
                    Color(0xFA0B0B0F),
                  ],
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.bottomStart,
              child: Padding(
                padding: EdgeInsets.all(width < 195 ? 12 : 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: nameSize,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (person.characters.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        person.characters.join(' / '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: roleSize,
                          height: 1.25,
                          color: const Color(0xFFE0DEE2),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Portrait extends StatelessWidget {
  const _Portrait({
    required this.person,
    required this.photo,
    this.withCaption = false,
  });
  final ImdbPerson person;
  final String? photo;
  final bool withCaption;

  @override
  Widget build(BuildContext context) {
    final fallback = _Monogram(person: person, withCaption: withCaption);
    final url = photo;
    return ExcludeSemantics(
      child: url == null || url.trim().isEmpty
          ? fallback
          : AppImage(
              url: url,
              alignment: const Alignment(0, -0.6),
              memCacheWidth: withCaption ? 512 : 320,
              placeholder: fallback,
              errorWidget: fallback,
            ),
    );
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram({required this.person, required this.withCaption});
  final ImdbPerson person;
  final bool withCaption;
  static const tones = [
    Color(0xFF775561),
    Color(0xFF455F79),
    Color(0xFF446B69),
    Color(0xFF716049),
    Color(0xFF60597C),
  ];

  @override
  Widget build(BuildContext context) {
    final words = person.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    final initials = [
      if (words.isNotEmpty) words.first.characters.first,
      if (words.length > 1) words.last.characters.first,
    ].join().toUpperCase();
    final tone =
        tones[(int.tryParse(person.id.replaceFirst('nm', '')) ?? 0) %
            tones.length];
    return CustomPaint(
      painter: _PortraitBackdrop(tone),
      child: Align(
        alignment: withCaption ? const Alignment(0, -0.29) : Alignment.center,
        child: FractionallySizedBox(
          widthFactor: 0.62,
          heightFactor: 0.28,
          child: FittedBox(
            child: initials.isEmpty
                ? const Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white70,
                  )
                : Text(
                    initials,
                    textScaler: TextScaler.noScaling,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 64,
                      height: 1.05,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -2,
                      color: Color(0xFFF2EAEB),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _PortraitBackdrop extends CustomPainter {
  const _PortraitBackdrop(this.tone);
  final Color tone;
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final light = RadialGradient(
      center: const Alignment(-0.85, -0.9),
      radius: 1.65,
      colors: [
        tone,
        Color.lerp(tone, AppColors.background, 0.5)!,
        AppColors.background,
      ],
    );
    canvas.drawRect(bounds, Paint()..shader = light.createShader(bounds));
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x20FFFFFF);
    final arc = Rect.fromCenter(
      center: Offset(size.width * 1.13, size.height * 0.94),
      width: size.width * 1.56,
      height: size.height * 1.35,
    );
    canvas.save();
    canvas.clipRect(bounds);
    canvas.drawOval(arc, ring);
    canvas.drawOval(arc.inflate(size.width * 0.1), ring);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PortraitBackdrop oldDelegate) => oldDelegate.tone != tone;
}

class _PersonDialog extends ConsumerWidget {
  const _PersonDialog({
    required this.person,
    required this.photo,
    required this.origin,
  });
  final ActorOrigin? origin;
  final String? photo;
  final ImdbPerson person;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context).textTheme;
    final life = [
      if (person.birth != null) 'Born ${person.birth}',
      if (person.death != null) 'Died ${person.death}',
    ].join(' · ');
    final portrait = SizedBox(
      width: 124,
      height: 154,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _Portrait(person: person, photo: photo),
      ),
    );
    final facts = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (person.characters.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'As ${person.characters.join(' / ')}',
              style: theme.titleMedium,
            ),
          ),
        if (life.isNotEmpty) Text(life),
        if (person.professions.isNotEmpty) Text(person.professions.join(' · ')),
      ],
    );
    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(person.name),
      content: SizedBox(
        width: origin == null ? 440 : 608,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                portrait,
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: facts,
                ),
              ],
            ),
            if (origin case final from?) ...[
              const SizedBox(height: 22),
              ActorLibrarySection(query: (personId: person.id, origin: from)),
            ],
            if (person.knownFor.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Known for', style: theme.titleSmall),
              for (final title in person.knownFor)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(title),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => openExternalLink(
            context,
            ref,
            Uri.https('www.imdb.com', '/name/${person.id}/'),
          ),
          child: const Text('View profile on IMDb'),
        ),
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
