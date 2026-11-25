import 'package:flutter/material.dart';

class AppDestination {
  const AppDestination(
    this.label,
    this.icon,
    this.path, {
    this.outlineIcon,
    this.inMobileDock = true,
  });

  final String label;
  final IconData icon;
  final IconData? outlineIcon;
  final String path;
  final bool inMobileDock;
}

const appDestinations = [
  AppDestination(
    'Home',
    Icons.home_rounded,
    '/home',
    outlineIcon: Icons.home_outlined,
  ),
  AppDestination('Live TV', Icons.live_tv_rounded, '/live'),
  AppDestination(
    'Movies',
    Icons.movie_rounded,
    '/movies',
    outlineIcon: Icons.movie_outlined,
  ),
  AppDestination(
    'Series',
    Icons.video_library_rounded,
    '/series',
    outlineIcon: Icons.video_library_outlined,
  ),
  AppDestination(
    'Search',
    Icons.search_rounded,
    '/search',
    inMobileDock: false,
  ),
  AppDestination(
    'Downloads',
    Icons.download_rounded,
    '/downloads',
    inMobileDock: false,
  ),
  AppDestination(
    'Settings',
    Icons.settings_rounded,
    '/settings',
    outlineIcon: Icons.settings_outlined,
  ),
];

/// Trailing destinations rendered icon-only on the right of the top bar.
const iconOnlyDestinations = 3;
