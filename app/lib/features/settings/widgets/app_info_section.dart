import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_icons/simple_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/external_link.dart';
import '../../../data/releases/release_repository.dart';
import 'settings_section.dart';

class AppInfoSection extends ConsumerStatefulWidget {
  const AppInfoSection({super.key});
  @override
  ConsumerState<AppInfoSection> createState() => _AppInfoSectionState();
}

class _AppInfoSectionState extends ConsumerState<AppInfoSection> {
  bool _checking = false;
  bool _checked = false;
  AppRelease? _release;
  String? _error;

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final release = await ref.read(releaseRepositoryProvider).latest();
      if (mounted) {
        setState(() {
          _release = release;
          _checked = true;
        });
      }
    } on ReleaseCheckException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not check for updates. Try again later.',
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final package = ref.watch(packageInfoProvider);
    final info = package.value;
    var newer = false;
    var comparable = info != null;
    if (_release != null && info != null) {
      try {
        newer = _release!.isNewerThan(info.version);
      } on FormatException {
        comparable = false;
      }
    }
    final status =
        _error ??
        (_checking
            ? 'Checking GitHub Releases…'
            : !_checked
            ? 'Check GitHub for a newer version.'
            : _release == null
            ? 'No public stable release is available yet.'
            : !comparable
            ? 'Latest release: ${_release!.tag}'
            : newer
            ? 'Update available: ${_release!.tag}'
            : 'You’re up to date.');
    return SettingsSection(
      label: 'App & updates',
      children: [
        SettingsTile(
          icon: Icons.info_outline_rounded,
          title: 'Zauxoflix',
          subtitle: info == null
              ? package.hasError
                    ? 'Installed version unavailable'
                    : 'Loading installed version…'
              : 'Version ${info.version}${info.buildNumber.isEmpty ? '' : ' (build ${info.buildNumber})'}',
        ),
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          child: Text(
            status,
            style: TextStyle(
              color: _error == null ? AppColors.textPrimary : AppColors.error,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Updates are downloaded and installed manually from GitHub. Choose the build for your device under Assets.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 12),
        SettingsAction(
          onPressed: _checking ? null : _check,
          busy: _checking,
          icon: Icons.refresh_rounded,
          title: _checking ? 'Checking…' : 'Check for updates',
        ),
        SettingsAction(
          onPressed: () => openExternalLink(
            context,
            ref,
            _release?.page ?? ReleaseRepository.releasesPage,
          ),
          icon: Icons.open_in_new_rounded,
          title: newer ? 'Download ${_release!.tag}' : 'Open GitHub Releases',
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(height: 1),
        ),
        const SettingsTile(
          icon: Icons.person_outline_rounded,
          title: 'Developed by Ahmad El-Khatib',
        ),
        const SizedBox(height: 8),
        const SettingsTile(
          icon: SimpleIcons.github,
          title: 'GitHub · github.com/ahmadteeb',
        ),
      ],
    );
  }
}
