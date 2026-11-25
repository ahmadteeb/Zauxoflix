# Changelog

## 1.1.0

### Added

- Separate movie and series recommendations based on My List, watch activity, language, genre, and release year. Home rotates its featured picks and caches recommendations and Top 10 charts by day. Charts include titles available in the current playlist.
- Trakt title matching, related titles, trailers, cast photos when available, and actor pages that link to other movies and series in the library. A separately prepared personal IMDb index supplies offline ratings, title metadata, and cast details.
- Global Search keeps recent queries and opened movies, series, and channels. The two lists save locally for each account and playlist and can be cleared independently.
- Regional Live TV collections with football broadcasters, variant selection, favorites, recents, and XMLTV matching. Alternate qualities and duplicate feeds group under one station when they represent the same channel.
- Download space checks, mobile background and Wi-Fi-only transfers, watched-episode removal, and header indicators for transfers and completed downloads.

### Changed

- Updated Home, phone and TV navigation, library filters, Settings, and sheets. Titles with missing artwork use placeholders that show their names.
- The player adds previous-episode navigation, remote-friendly seek controls, playback recovery, and frame previews on supported streams and devices.
- LG webOS playback and trailer packaging use native webOS plugins. Back returns through the player, sheets, and screens before asking to exit from Home.
- Normalized search handles Arabic spelling variants and common aliases. Playlist sync can reuse validators, discover XMLTV feeds, and keep the local library when only guide settings change.

### Database

- The app upgrades SQLite from schema 6 to 13. The upgrade adds catalog indexes and backfills, discovery metadata, recommendation snapshots, watched episodes, and local Live TV viewing and tuning tables. Existing playlists, watch progress, favorites, and download records carry forward.
- Supabase keeps the four existing forward migrations. This release adds a [deployment script and upgrade guide](supabase/README.md#deployment-and-checks) for fork operators.
