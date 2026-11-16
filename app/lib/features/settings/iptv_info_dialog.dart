import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/app_database.dart';
import '../../data/xtream/xtream_api.dart';
import '../../data/xtream/xtream_models.dart';

final iptvInfoProvider = FutureProvider.autoDispose
    .family<XtreamUserInfo, Source>((ref, source) async {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          responseType: ResponseType.plain,
        ),
      );
      ref.onDispose(() => dio.close(force: true));
      return XtreamApi(
        XtreamCredentials(
          serverUrl: source.serverUrl,
          username: source.username,
          password: source.password,
        ),
        dio: dio,
      ).authenticate();
    });

/// Playlist paths and query strings can carry credentials; summaries show the origin only.
String sourceOrigin(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null ||
      !uri.hasAuthority ||
      !const ['http', 'https'].contains(uri.scheme)) {
    return 'Unknown provider';
  }
  return uri.origin;
}

String providerDate(DateTime value) {
  final date = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}

Future<void> showIptvInfoDialog(BuildContext context, Source source) =>
    showDialog<void>(
      context: context,
      builder: (_) => _IptvInfoDialog(source: source),
    );

class _IptvInfoDialog extends ConsumerWidget {
  const _IptvInfoDialog({required this.source});
  final Source source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xtream = source.sourceType == SourceType.xtream;
    final account = xtream ? ref.watch(iptvInfoProvider(source)) : null;
    final info = account?.asData?.value;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.dns_outlined,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'IPTV information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      source.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      xtream ? 'Xtream Codes account' : 'M3U playlist',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    if (xtream) ...[
                      if (account!.isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text('Checking provider account…'),
                              ),
                            ],
                          ),
                        )
                      else if (account.hasError)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Could not load account information. Check your connection or try again later.',
                                style: TextStyle(color: AppColors.error),
                              ),
                              TextButton.icon(
                                onPressed: () =>
                                    ref.invalidate(iptvInfoProvider(source)),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      else if (info != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    info.authenticated
                                        ? Icons.verified_outlined
                                        : Icons.error_outline_rounded,
                                    color: info.authenticated
                                        ? AppColors.textPrimary
                                        : AppColors.error,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Account status',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          info.authenticated
                                              ? info.status
                                              : 'Credentials rejected',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 32),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final expiry = _Summary(
                                    'Expires',
                                    info.expiresAt == null
                                        ? 'Not reported by provider'
                                        : providerDate(info.expiresAt!),
                                  );
                                  final connections = _Summary(
                                    'Connections',
                                    '${info.activeConnections ?? '—'} / ${info.maxConnections ?? '—'} in use',
                                  );
                                  return constraints.maxWidth < 360 ||
                                          MediaQuery.textScalerOf(
                                                context,
                                              ).scale(14) >
                                              20
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            expiry,
                                            const SizedBox(height: 16),
                                            connections,
                                          ],
                                        )
                                      : Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(child: expiry),
                                            const SizedBox(width: 20),
                                            Expanded(child: connections),
                                          ],
                                        );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ] else ...[
                      const Text(
                        'M3U playlists do not report account status, expiry or connection limits. Contact your IPTV provider for those details.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    const _SectionLabel('Provider details'),
                    _InfoRow(
                      'Source type',
                      xtream ? 'Xtream Codes' : 'M3U playlist',
                    ),
                    _InfoRow('Provider', sourceOrigin(source.serverUrl)),
                    if (xtream) _InfoRow('Username', source.username),
                    if (source.epgUrl?.isNotEmpty ?? false)
                      _InfoRow('EPG provider', sourceOrigin(source.epgUrl!)),
                    _InfoRow(
                      'Last catalog sync',
                      source.lastSyncAt == null
                          ? 'Never synced'
                          : providerDate(source.lastSyncAt!),
                    ),
                    if (info != null) ...[
                      const SizedBox(height: 20),
                      const _SectionLabel('Subscription details'),
                      _InfoRow(
                        'Maximum connections',
                        info.maxConnections?.toString() ?? 'Not reported',
                      ),
                      _InfoRow(
                        'Active connections',
                        info.activeConnections?.toString() ?? 'Not reported',
                      ),
                      if (info.isTrial != null)
                        _InfoRow(
                          'Account type',
                          info.isTrial! ? 'Trial' : 'Standard',
                        ),
                      if (info.createdAt != null)
                        _InfoRow('Created', providerDate(info.createdAt!)),
                      if (info.outputFormats.isNotEmpty)
                        _InfoRow(
                          'Output formats',
                          info.outputFormats.join(', '),
                        ),
                    ],
                    const SizedBox(height: 20),
                    const Text(
                      'Account details are supplied by your IPTV provider. Zauxoflix is free.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (xtream)
                    OutlinedButton.icon(
                      onPressed: account!.isLoading
                          ? null
                          : () => ref.invalidate(iptvInfoProvider(source)),
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      label: const Text('Refresh'),
                    ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    ),
  );
}

class _Summary extends StatelessWidget {
  const _Summary(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
      const SizedBox(height: 6),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.outline)),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final title = Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        );
        final content = SelectableText(
          value,
          style: const TextStyle(fontSize: 14, height: 1.5),
        );
        if (constraints.maxWidth < 360 ||
            MediaQuery.textScalerOf(context).scale(14) > 20) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 6), content],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 160, child: title),
            const SizedBox(width: 16),
            Expanded(child: content),
          ],
        );
      },
    ),
  );
}
