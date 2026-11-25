import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/form_factor.dart';
import '../../core/theme/app_theme.dart';
import '../../data/backend/auth_models.dart';
import '../../data/backend/backend_providers.dart';
import '../../data/db/app_database.dart';
import '../../data/downloads/download_preferences.dart';
import '../../data/providers.dart';
import '../downloads/download_network_setting.dart';
import '../player/autoplay_preference.dart';
import '../shell/top_nav_bar.dart';
import 'account_dialogs.dart';
import 'iptv_info_dialog.dart';
import 'pair_tv_dialog.dart';
import 'widgets/app_info_section.dart';
import 'widgets/settings_navigation.dart';
import 'widgets/settings_section.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _AccountIdentity extends StatelessWidget {
  const _AccountIdentity({required this.name, required this.details});

  final String name, details;

  @override
  Widget build(BuildContext context) {
    final words = name.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    final initials = words.take(2).map((word) => word.characters.first).join();
    final corners = BorderRadius.circular(16);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: corners,
        color: MediaQuery.highContrastOf(context)
            ? AppColors.surfaceLight
            : null,
        gradient: MediaQuery.highContrastOf(context)
            ? null
            : AppColors.panelGradient,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Container(
                height: 54,
                width: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.selectionSurface,
                ),
                child: initials.isEmpty
                    ? const Icon(Icons.person_outline_rounded)
                    : Text(
                        initials.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        textScaler: TextScaler.noScaling,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.selectionAccent,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details,
                    style: const TextStyle(
                      color: Color(0xFFD1C9D7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncStatus extends StatelessWidget {
  const _SyncStatus({required this.state, required this.lastSync});

  final SyncState state;
  final DateTime? lastSync;

  @override
  Widget build(BuildContext context) {
    final local = lastSync?.toLocal();
    final format = MaterialLocalizations.of(context);
    final timestamp = local == null
        ? 'Never synced'
        : 'Last synced ${format.formatMediumDate(local)} at ${format.formatTimeOfDay(TimeOfDay.fromDateTime(local), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}';
    final (icon, label, color) = switch (state) {
      SyncRunning(:final stage) => (
        Icons.sync_rounded,
        stage,
        const Color(0xFFCAD3FF),
      ),
      SyncFailure(:final message) => (
        Icons.error_outline_rounded,
        'Sync failed: $message',
        AppColors.error,
      ),
      SyncSuccess() => (
        Icons.check_circle_outline_rounded,
        'Catalog up to date.',
        const Color(0xFFACE1C8),
      ),
      SyncIdle() => (
        Icons.schedule_rounded,
        timestamp,
        AppColors.textSecondary,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.controlSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label, style: TextStyle(color: color)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _signingOut = false;
  bool _removing = false;
  SettingsGroup _section = SettingsGroup.account;
  final _scroll = ScrollController();
  final _contentKey = GlobalKey(debugLabel: 'Settings panels');

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formFactor = formFactorOf(context, ref);
    final authState = ref.watch(authControllerProvider);
    final user = authState is Authenticated ? authState.user : null;
    final sections = <SettingsGroup, Widget>{
      if (user != null) SettingsGroup.account: _accountSettings(user),
      SettingsGroup.playlist: _playlistSettings(),
      if (user != null) SettingsGroup.playback: _playbackSettings(user.id),
      if (!kTvBuild) SettingsGroup.downloads: _downloadsSettings(formFactor),
      SettingsGroup.layout: _layoutSettings(),
      SettingsGroup.about: const AppInfoSection(),
    };
    final selected = sections.containsKey(_section)
        ? _section
        : SettingsGroup.playlist;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: ListView(
          controller: _scroll,
          padding: EdgeInsets.fromLTRB(
            formFactor.gutter,
            formFactor == FormFactor.mobile ? 10 : kTopNavHeight + 18,
            formFactor.gutter,
            32,
          ),
          children: [
            Semantics(
              header: true,
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: formFactor == FormFactor.mobile ? 32 : 44,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.25,
                ),
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide =
                    constraints.maxWidth >= 730 &&
                    MediaQuery.textScalerOf(context).scale(14) <= 20;
                final navigation = SettingsNavigation(
                  groups: sections.keys.toList(),
                  selected: selected,
                  wide: wide,
                  onSelect: (section) {
                    if (section == selected) return;
                    setState(() => _section = section);
                    if (_scroll.hasClients) _scroll.jumpTo(0);
                  },
                );
                final content = FocusTraversalGroup(
                  key: _contentKey,
                  child: Column(
                    children: [
                      for (final entry in sections.entries)
                        Visibility(
                          key: ValueKey(entry.key),
                          visible: entry.key == selected,
                          maintainState: true,
                          child: entry.value,
                        ),
                    ],
                  ),
                );
                return wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: constraints.maxWidth >= 980 ? 254 : 212,
                            child: navigation,
                          ),
                          const SizedBox(width: 18),
                          Expanded(child: content),
                        ],
                      )
                    : Column(
                        children: [
                          navigation,
                          const SizedBox(height: 14),
                          content,
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountSettings(BackendUser user) => SettingsSection(
    label: 'Account',
    children: [
      _AccountIdentity(
        name: _displayName(user),
        details: _accountDetails(user),
      ),
      const SizedBox(height: 12),
      SettingsAction(
        icon: Icons.edit_outlined,
        title: 'Edit profile',
        onPressed: () => showEditProfileDialog(context, user),
      ),
      SettingsAction(
        icon: Icons.password_rounded,
        title: 'Change password',
        onPressed: () async {
          final changed = await showChangePasswordDialog(context);
          if (changed == true) {
            _showAlert('Password changed', 'Your password has been updated.');
          }
        },
      ),
      SettingsAction(
        icon: Icons.tv_rounded,
        title: 'Pair a TV',
        onPressed: () async {
          final label = await showPairTvDialog(context);
          if (label != null) {
            _showAlert(
              'TV paired',
              '${label.isEmpty ? 'The TV' : label} is signing '
                  'in to your account now.',
            );
          }
        },
      ),
      const SizedBox(height: 12),
      SettingsAction(
        icon: Icons.logout_rounded,
        title: _signingOut ? 'Signing out…' : 'Sign out',
        busy: _signingOut,
        destructive: true,
        onPressed: _signingOut ? null : _confirmSignOut,
      ),
    ],
  );

  Widget _playbackSettings(String viewerId) {
    final preference = autoplayPreferenceProvider(viewerId);
    final saved = ref.watch(preference);
    return SettingsSection(
      label: 'Playback',
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.skip_next_rounded),
          title: const Text('Autoplay next episode'),
          subtitle: const Text(
            'Show a three-second countdown as the current episode ends.',
          ),
          value: saved.value ?? false,
          onChanged: saved.hasValue && !saved.isLoading
              ? (enabled) async {
                  try {
                    await ref.read(preference.notifier).save(enabled);
                  } catch (_) {
                    if (mounted) {
                      _showAlert(
                        'Autoplay',
                        'Could not save this setting. Please try again.',
                      );
                    }
                  }
                }
              : null,
        ),
        if (saved.hasError)
          TextButton(
            onPressed: () => ref.invalidate(preference),
            child: const Text('Retry loading autoplay setting'),
          ),
      ],
    );
  }

  Widget _playlistSettings() {
    final active = ref.watch(activeSourceProvider);
    final source = active.value;
    final syncState = ref.watch(syncControllerProvider);
    final syncing = syncState is SyncRunning;
    final busy = syncing || _removing;

    return SettingsSection(
      label: 'Playlist',
      children: [
        if (source == null && active.isLoading)
          const SettingsTile(
            icon: Icons.playlist_play_rounded,
            title: 'Loading playlist…',
          )
        else if (source == null && active.hasError)
          SettingsAction(
            icon: Icons.refresh_rounded,
            title: 'Retry loading playlist',
            onPressed: () => ref.invalidate(activeSourceProvider),
          )
        else if (source == null) ...[
          const SettingsTile(
            icon: Icons.playlist_remove_rounded,
            title: 'No playlist configured',
            subtitle: 'Connect a playlist to start watching.',
          ),
          const SizedBox(height: 12),
          SettingsAction(
            icon: Icons.playlist_add_rounded,
            title: 'Connect a playlist',
            onPressed: () => context.push('/setup'),
          ),
        ] else ...[
          SettingsTile(
            icon: Icons.dns_rounded,
            title: source.name,
            subtitle: sourceOrigin(source.serverUrl),
          ),
          const SizedBox(height: 12),
          _SyncStatus(state: syncState, lastSync: source.lastSyncAt),
          const SizedBox(height: 12),
          SettingsAction(
            icon: Icons.sync_rounded,
            title: syncing ? 'Syncing playlist…' : 'Sync now',
            busy: syncing,
            onPressed: busy
                ? null
                : () => ref
                      .read(syncControllerProvider.notifier)
                      .syncSource(source),
          ),
          SettingsAction(
            icon: Icons.info_outline_rounded,
            title: 'IPTV information',
            onPressed: () => showIptvInfoDialog(context, source),
          ),
          SettingsAction(
            icon: Icons.swap_horiz_rounded,
            title: 'Change playlist',
            onPressed: busy ? null : () => context.push('/setup'),
          ),
          const SizedBox(height: 12),
          SettingsAction(
            icon: Icons.delete_outline_rounded,
            title: _removing ? 'Removing playlist…' : 'Remove playlist',
            destructive: true,
            busy: _removing,
            onPressed: busy ? null : () => _confirmRemove(source),
          ),
        ],
      ],
    );
  }

  Widget _downloadsSettings(FormFactor form) => SettingsSection(
    label: 'Downloads',
    children: [
      SettingsAction(
        icon: Icons.folder_open_rounded,
        title: 'Manage downloads',
        subtitle: 'Videos saved on this device for offline playback.',
        onPressed: () => context.go('/downloads'),
      ),
      if (supportsMobileDownloads && !form.isTv)
        const DownloadNetworkSetting(
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
          icon: Icons.wifi_rounded,
        ),
    ],
  );

  Widget _layoutSettings() {
    final override = ref.watch(formFactorOverrideProvider);
    return SettingsSection(
      label: 'Layout mode',
      children: [
        for (final (label, icon, value) in <(String, IconData, FormFactor?)>[
          ('Auto-detect', Icons.auto_awesome_outlined, null),
          ('Phone', Icons.smartphone_rounded, FormFactor.mobile),
          ('Tablet', Icons.tablet_mac_rounded, FormFactor.tablet),
          ('Desktop', Icons.desktop_windows_outlined, FormFactor.desktop),
          ('TV', Icons.tv_rounded, FormFactor.tv),
        ])
          SettingsAction(
            icon: icon,
            title: label,
            subtitle: value == null
                ? 'Adapts to this device and screen size.'
                : null,
            selected: override == value,
            onPressed: () =>
                ref.read(formFactorOverrideProvider.notifier).set(value),
          ),
      ],
    );
  }

  static String _displayName(BackendUser user) {
    final name = [
      user.firstName,
      user.lastName,
    ].whereType<String>().join(' ').trim();
    return name.isEmpty ? user.email : name;
  }

  /// Email (when a name is shown above it), phone, and the session note —
  /// one per line.
  static String _accountDetails(BackendUser user) => [
    if (_displayName(user) != user.email) user.email,
    if (user.phone != null) user.phone!,
    'Signed in on this device',
  ].join('\n');

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        // Bound the width — on desktop the dialog otherwise stretches to fit
        // the whole text on one line.
        content: const SizedBox(
          width: 380,
          child: Text(
            'This removes the cached catalog, favorites and watch progress '
            'from this device. Everything stays synced to your account and '
            'comes back when you sign in.',
          ),
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _signingOut) return;
    setState(() => _signingOut = true);
    try {
      await ref.read(authControllerProvider.notifier).logout();
    } catch (_) {
      _showAlert(
        'Sign out failed',
        'Could not finish signing out. Please try again.',
      );
    } finally {
      // Normally the router has already swapped to /login; reset in case the
      // screen is still mounted (e.g. logout failed midway).
      if (mounted) setState(() => _signingOut = false);
    }
  }

  Future<void> _confirmRemove(Source source) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove playlist?'),
        content: const Text(
          'This removes the playlist from your account and deletes the '
          'cached catalog from this device.',
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true ||
        !mounted ||
        _removing ||
        ref.read(activeSourceProvider).value?.id != source.id ||
        ref.read(syncControllerProvider) is SyncRunning) {
      return;
    }
    setState(() => _removing = true);
    try {
      // Remove from the account vault first — otherwise the next provision
      // would just restore it onto this device.
      await ref.read(provisionRepositoryProvider).deleteRemoteSource();
      await ref.read(databaseProvider).deleteSource(source.id);
    } catch (_) {
      _showAlert(
        'Connection failed',
        'Couldn\'t reach the server — try again.',
      );
    } finally {
      if (mounted) setState(() => _removing = false);
    }
  }

  void _showAlert(String title, String message) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
