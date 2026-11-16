import 'package:flutter/material.dart';

enum MediaType { live, movie, series }

/// Lightweight view-model for anything rendered as a poster/tile: a movie,
/// series, or live channel. Screens map DB rows into this.
class MediaItem {
  const MediaItem({
    required this.title,
    this.subtitle = '',
    this.imageUrl,
    this.type,
    this.id,
    this.containerExtension,
    this.progress,
    this.badge,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;

  /// What opens when the tile is selected; null for purely decorative items.
  final MediaType? type;
  final int? id;
  final String? containerExtension;

  /// 0..1 watched fraction — renders a progress bar on the card.
  final double? progress;

  /// Short overlay chip on the card, e.g. "S2 E2" on Continue Watching.
  final String? badge;

  /// Deterministic placeholder color for items without artwork.
  Color get color => HSLColor.fromAHSL(
    1,
    (title.hashCode % 360).toDouble().abs(),
    0.45,
    0.32,
  ).toColor();
}
