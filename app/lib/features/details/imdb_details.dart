import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/external_link.dart';
import '../../data/discovery/trakt_client.dart';
import '../../data/discovery/actor_library.dart';
import '../../data/discovery/imdb_index.dart';
import 'cast_gallery.dart';

class ImdbDetails extends ConsumerWidget {
  const ImdbDetails({
    super.key,
    required this.data,
    required this.imdbId,
    required this.credits,
    this.origin,
  });
  final ImdbTitle? data;
  final String? imdbId;
  final List<CastCredit> credits;
  final ActorOrigin? origin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = this.data;
    final theme = Theme.of(context).textTheme;
    final photos = {for (final credit in credits) credit.id: credit.photo};
    final hasImdbCast = data?.cast.isNotEmpty ?? false;
    final cast = hasImdbCast
        ? data!.cast
        : <ImdbPerson>[
            for (final credit in credits)
              (
                id: credit.id,
                name: credit.name,
                characters: credit.roles,
                birth: null,
                death: null,
                professions: const [],
                knownFor: const [],
              ),
          ];
    final year = data?.year;
    final facts = [
      if (data != null) ...[
        data.kind,
        if (year != null)
          data.endYear == null || data.endYear == year
              ? '$year'
              : '$year–${data.endYear}',
        if (data.minutes != null) '${data.minutes} min',
        ...data.genres,
      ],
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (data != null) Text('IMDb details', style: theme.titleLarge),
            if (data?.rating != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: Color(0xFFF5C518),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${data!.rating!.toStringAsFixed(1)}/10',
                    style: theme.titleSmall,
                  ),
                ],
              ),
            if (imdbId case final id?)
              TextButton.icon(
                onPressed: () => openExternalLink(
                  context,
                  ref,
                  Uri.https('www.imdb.com', '/title/$id/'),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('View on IMDb'),
              ),
          ],
        ),
        if (data != null) ...[
          const SizedBox(height: 6),
          Text(data.title, style: theme.titleMedium),
          if (data.original != null) Text('Original title · ${data.original}'),
          Text(facts, style: const TextStyle(color: AppColors.textSecondary)),
          if (data.votes != null)
            Text(
              '${MaterialLocalizations.of(context).formatDecimal(data.votes!)} IMDb votes',
              style: theme.bodySmall,
            ),
        ],
        if (cast.isNotEmpty) ...[
          const SizedBox(height: 24),
          CastGallery(
            title: hasImdbCast ? 'Principal cast' : 'Cast',
            cast: cast,
            photos: photos,
            origin: origin,
          ),
        ],
        if (credits.isNotEmpty &&
            (!hasImdbCast || photos.values.any((p) => p != null)))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              hasImdbCast ? 'Cast photos from Trakt' : 'Cast from Trakt',
              style: theme.bodySmall,
            ),
          ),
        if (data != null) ...[
          const SizedBox(height: 10),
          Text(
            'Information courtesy of IMDb (https://www.imdb.com). Used with permission.',
            style: theme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}
