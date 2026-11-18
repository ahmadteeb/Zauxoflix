import 'package:flutter/material.dart';

class AppDestination {
  const AppDestination(this.label, this.icon, this.path);

  final String label;
  final IconData icon;
  final String path;
}

const appDestinations = [
  AppDestination('Home', Icons.home_rounded, '/home'),
  AppDestination('Live TV', Icons.live_tv_rounded, '/live'),
  AppDestination('Movies', Icons.movie_rounded, '/movies'),
  AppDestination('Series', Icons.video_library_rounded, '/series'),
  AppDestination('Search', Icons.search_rounded, '/search'),
  AppDestination('Downloads', Icons.download_rounded, '/downloads'),
  AppDestination('Settings', Icons.settings_rounded, '/settings'),
];

/// Trailing destinations rendered icon-only on the right of the top bar.
const iconOnlyDestinations = 3;
