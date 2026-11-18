import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/form_factor.dart';
import '../../core/theme/app_theme.dart';
import '../../data/backend/auth_models.dart';
import '../../data/backend/backend_providers.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import 'account_dialogs.dart';
import 'iptv_info_dialog.dart';
import 'widgets/app_info_section.dart';
import 'widgets/settings_section.dart';
import 'pair_tv_dialog.dart';
import '../shell/top_nav_bar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _signingOut = false;
  bool _removing = false;

  @override
  Widget build(BuildContext context) {
    final formFactor = formFactorOf(context, ref);
    final authState = ref.watch(authControllerProvider);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.settingsMaxWidth),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            formFactor.gutter,
            formFactor == FormFactor.mobile ? 24 : kTopNavHeight + 16,
            formFactor.gutter,
            24,
          ),
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            if (authState case Authenticated(:final user)) ...[
              SettingsSection(
                label: 'ACCOUNT',
                children: [
                  SettingsTile(
                    icon: Icons.person_outline_rounded,
                    title: _displayName(user),
                    subtitle: _accountDetails(user),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => showEditProfileDialog(context, user),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit profile'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final changed = await showChangePasswordDialog(
                            context,
                          );
                          if (changed == true) {
                            _showAlert(
                              'Password changed',
                              'Your password has been updated.',
                            );
                          }
                        },
                        icon: const Icon(Icons.password_rounded, size: 18),
                        label: const Text('Change password'),
                      ),
                      OutlinedButton.icon(
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
                        icon: const Icon(Icons.tv_rounded, size: 18),
                        label: const Text('Pair a TV'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _signingOut ? null : _confirmSignOut,
                        icon: _signingOut
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.logout_rounded, size: 18),
                        label: Text(_signingOut ? 'Signing out…' : 'Sign out'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            _buildPlaylistCard(context),
            const SizedBox(height: 24),
            if (!kTvBuild) ...[
              SettingsSection(
                label: 'DOWNLOADS',
                children: [
                  const SettingsTile(
                    icon: Icons.download_rounded,
                    title: 'Downloads',
                    subtitle:
                        'Videos saved on this device for offline '
                        'playback.',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/downloads'),
                    icon: const Icon(Icons.folder_open_rounded, size: 18),
                    label: const Text('Manage downloads'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            const AppInfoSection(),
            const SizedBox(height: 24),
            _buildLayoutCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(BuildContext context) {
    final source = ref.watch(activeSourceProvider).value;
    final syncState = ref.watch(syncControllerProvider);
    final busy = syncState is SyncRunning || _removing;

    return SettingsSection(
      label: 'PLAYLIST',
      children: [
        if (source == null)
          const SettingsTile(
            icon: Icons.playlist_remove_rounded,
            title: 'No playlist configured',
            subtitle: 'Connect a playlist to start watching.',
          )
        else ...[
          SettingsTile(
            icon: Icons.dns_rounded,
            title: source.name,
            subtitle: source.lastSyncAt == null
                ? '${sourceOrigin(source.serverUrl)} — never synced'
                : '${sourceOrigin(source.serverUrl)} — last synced '
                      '${_formatWhen(source.lastSyncAt!)}',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => showIptvInfoDialog(context, source),
                icon: const Icon(Icons.info_outline_rounded, size: 18),
                label: const Text('IPTV information'),
              ),
              FilledButton.icon(
                onPressed: busy
                    ? null
                    : () => ref
                          .read(syncControllerProvider.notifier)
                          .syncSource(source),
                style: FilledButton.styleFrom(
                  // Compact, matching the outlined buttons beside it.
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  backgroundColor: AppColors.primary,
                ),
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: const Text('Sync now'),
              ),
              ...[
                OutlinedButton.icon(
                  onPressed: busy ? null : () => context.push('/setup'),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('Change'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : () => _confirmRemove(source),
                  icon: _removing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Remove'),
                ),
              ],
            ],
          ),
          switch (syncState) {
            SyncRunning(:final stage) => Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      stage,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            SyncFailure(:final message) => Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Sync failed: $message',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
            SyncSuccess() => const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Catalog up to date.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            SyncIdle() => const SizedBox.shrink(),
          },
        ],
      ],
    );
  }

  Widget _buildLayoutCard() {
    final override = ref.watch(formFactorOverrideProvider);
    return SettingsSection(
      label: 'LAYOUT MODE',
      children: [
        // Plain tiles instead of RadioGroup: its roving arrow-key selection
        // would switch the layout mode while a D-pad user merely scrolls past.
        for (final (label, value) in <(String, FormFactor?)>[
          ('Auto-detect', null),
          for (final ff in FormFactor.values) (ff.name.toUpperCase(), ff),
        ])
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(
              override == value
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: override == value
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            title: Text(label),
            onTap: () =>
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

  static String _formatWhen(DateTime time) {
    final local = time.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

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
    if (confirmed != true || !mounted) return;
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
    if (confirmed != true || !mounted) return;
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
