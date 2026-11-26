# UI review and design system

The review keeps Zauxoflix's existing dark streaming-player identity: red primary actions, neutral surfaces, restrained borders, readable white/gray text, and visible keyboard/TV focus. It does not introduce a second UI framework or a disconnected web/CSS token system.

## Token layers

The native source of truth is `app/lib/core/theme/app_theme.dart`:

| Layer | Code | Purpose |
| --- | --- | --- |
| Primitive | `AppPalette`, `AppSpacing` | Existing palette, readable error tint, base spacing and 48dp touch target |
| Semantic | `AppColors` | Background/surfaces, primary action, foreground/muted text, focus, outline, error |
| Component | `AppLayout`, `AppTheme` | Settings width/card geometry, control minimum sizes, disabled/focused states, input and navigation themes |

New Settings components use these tokens. `SettingsSection` uses Material surfaces so ink and keyboard focus feedback remain visible. Actions use native Material buttons, wrap when space is tight, and share a minimum 48×48dp target. Muted text stays distinct from disabled controls. Errors use the lighter semantic error color rather than the darker brand red on dark surfaces.

## Responsive refinement

The follow-up review uses widget layout and interaction checks without taking or regenerating screenshots.

- Automatic layout follows window width: phone below 700dp, tablet below 1100dp, desktop above it; detected TV mode keeps remote navigation. Resizing preserves the current Settings route while the shell changes navigation.
- Compact authentication and playlist forms use smaller gutters and respect safe areas. Narrow browse filters stack instead of squeezing the category label.
- IPTV information now has a fixed header/footer around a scrollable body, an account summary, expiry/connection metrics, and grouped provider rows. Rows stack on phones and with enlarged text.
- The QR and code share one bordered panel and remain beside each other at phone and TV widths. Supporting instructions sit below the panel rather than squeezing the code.
- Details hide the side poster when width or text scale leaves too little reading space. Season selectors grow with text size.
- Password recovery starts with the email request; the “I already have a code” shortcut has been removed.

## Changes from the earlier review

- Replaced the mobile floating cast overlay with an inset-aware header so it cannot cover search or sorting controls.
- Reduced mobile bottom navigation to Home / Live TV / Movies / Series / More. The More sheet opens Search and Settings, preserving branch state and back behavior.
- Replaced scaled-down desktop/tablet navigation with full-size buttons, compact icons and tooltips at narrow widths, and scrolling when needed. The existing D-pad focus bridge is retained.
- Added safe-area handling to shell layouts and normal keyboard interaction to the cast button.
- Let the hero grow with its content. Long titles, large text and wrapping actions cannot exceed a fixed banner height; a loading hero no longer offers an inert Play action.
- Made compact sort controls, Live TV headers/empty previews, the guide header, episode artwork, skeleton season chips, and source/pairing headers adapt to constrained space.
- Made empty/search states scrollable and added a search failure/retry state instead of a perpetual loading placeholder. Added a clear-search tooltip.
- Preserved 48dp transport controls instead of shrinking them; player auxiliary controls move below transport at narrower widths. Remote-control content scrolls in short viewports.
- Added tooltips for player transport and retained white focus outlines. Focus scaling, transitions, hero crossfades, and skeleton shimmer respect reduced-motion preferences.
- Replaced the Live TV polling delay with a cancellable timer; leaving the view cancels the poll immediately.
- Added a Settings sign-out error state and consistent card/button feedback. Profile, password, pairing and recovery dialogs scroll when a keyboard or large text reduces the available height. Dismissed account/setup forms ignore late request errors instead of calling setState after disposal.

## Settings flows

**IPTV information:** provider origin, source type, username for Xtream, last sync, and reported account metadata. The dialog supports loading, retry, refresh, unavailable fields, and M3U-specific explanatory text. It does not display passwords, URL userinfo, playlist paths, or query-string credentials. Expiry and trial information refer to the user's IPTV provider; the app remains free.

**App & updates:** installed package version/build is loaded once through a provider. A deliberate check reads GitHub's latest public stable release without credentials. Semantic versions determine whether the release is newer. Missing releases, invalid tags, request limits and connectivity failures have explicit states. Download opens the exact release page; no executable is downloaded or installed by the app. Browser failure presents a selectable/copyable URL for TV and other devices.

**Developer:** Ahmad El-Khatib is credited with a person icon and an actionable GitHub profile link using GitHub's official mark. External links open in the system browser.

## Automated layout coverage

`app/test/responsive_ui_test.dart` exercises Home, Live TV, Movies, Series, Search, Settings, Guide, Downloads, playlist setup, sign-in, registration, shared details, featured content, top navigation, and IPTV/profile/password/pairing/recovery dialogs with simulated keyboard insets at:

| Viewport | Text scale | Layout |
| --- | --- | --- |
| 360×640 | 1.3 | Compact phone |
| 600×960 | 1.2 | Narrow window |
| 1024×600 | 1.5 | Short tablet / desktop window |
| 320×720 | 1.0 | Small phone |
| 375×812 | 2.0 | Phone with enlarged text |
| 844×390 | 1.4 | Phone landscape |
| 768×1024 | 1.2 | Tablet |
| 1440×900 | 1.0 | Desktop |
| 1920×1080 | 1.0 | TV layout |

Tests also exercise mobile More → Settings navigation, version comparison, update-page launching, provider account details, credential redaction, and the no-browser fallback. Existing routing/back, pairing, Live TV visibility, sync and playback-state tests remain in the full suite.

The existing README screenshots were rendered in the earlier review from actual widgets with synthetic data.

## TV QR pairing

The TV displays a high-contrast QR beside its manual code in a single responsive panel, including on narrow screens. Signed-in users open Settings → Pair a TV → Scan QR code, then confirm the populated code with Pair. Android, iOS, and macOS support the camera scanner; other platforms retain manual entry. Denied permission and missing cameras show a manual-entry exit. QR validation rejects unrelated codes and different Supabase deployments, and duplicate scan events return only once. The existing server controls expiry and single-use login. QR payloads contain no device secret or login token.

Parser and widget tests cover validation, confirmation before claiming, unsupported platforms, camera denial, duplicate detections, and TV session handoff. Physical camera scanning and native builds still require device verification.

## Practical limits

Layout tests use cached demo content and cannot prove real provider compatibility, decoder behavior, download reliability, native browser/installer behavior, or physical Android TV remote behavior. Check those on target devices before a release. The GitHub latest-release endpoint returned 404 during this review; the app handles that state, while newer-release UI is verified with fixtures. Automated layout checks do not replace a full screen-reader or physical-device audit.
