import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/app_platform.dart';
import '../../core/responsive/form_factor.dart';
import '../../core/widgets/external_link.dart';

const _appOrigin = 'https://com.zauxoflix.zauxoflix';
const _webOsLauncher = MethodChannel('webos_plugin');

Future<bool> launchWebOsTrailer(String video, String title) async {
  if (!RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(video)) return false;
  try {
    return await _webOsLauncher.invokeMethod<bool>('app_manager/launch', {
          'id': 'com.flutter.app.zauxoflix.trailer',
          'params': {'video': video, 'title': title},
        }) ??
        false;
  } on PlatformException {
    return false;
  } on MissingPluginException {
    return false;
  }
}

Future<void> openTitleTrailer(
  BuildContext context,
  String video,
  String title,
) async {
  // Keep the native details route current while the app's webOS player card
  // is in front. Remote Back on that card resumes the same title.
  if (isWebOsPlatform && await launchWebOsTrailer(video, title)) return;
  if (!context.mounted || ModalRoute.of(context)?.isCurrent != true) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => TrailerScreen(video: video, title: title),
    ),
  );
}

final trailerEmbedAvailableProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  if (isWebOsPlatform || isTizenPlatform) return false;
  try {
    if (Platform.isWindows) {
      return await WebViewEnvironment.getAvailableVersion() != null;
    }
    if (Platform.isAndroid) {
      return await InAppWebViewController.getCurrentWebViewPackage() != null;
    }
  } catch (_) {
    return false;
  }
  return Platform.isIOS || Platform.isMacOS;
});

final _playerPageProvider = FutureProvider<String>(
  (ref) => rootBundle.loadString('assets/trailer/player.html'),
);

class TrailerScreen extends ConsumerStatefulWidget {
  const TrailerScreen({super.key, required this.video, required this.title});
  final String video, title;
  @override
  ConsumerState<TrailerScreen> createState() => _TrailerScreenState();
}

class _TrailerScreenState extends ConsumerState<TrailerScreen> {
  final _toggleFocus = FocusNode(debugLabel: 'Trailer playback');
  InAppWebViewController? _controller;
  String _playerState = 'loading';
  bool _failed = false;

  @override
  void dispose() {
    _toggleFocus.dispose();
    super.dispose();
  }

  void _close() {
    if (mounted && ModalRoute.of(context)?.isCurrent == true) {
      Navigator.pop(context);
    }
  }

  void _fail() {
    if (!mounted) return;
    setState(() {
      _controller = null;
      _failed = true;
    });
  }

  Future<void> _retry() async {
    if (isWebOsPlatform &&
        await launchWebOsTrailer(widget.video, widget.title)) {
      _close();
      return;
    }
    if (!mounted) return;
    ref.invalidate(trailerEmbedAvailableProvider);
    ref.invalidate(_playerPageProvider);
    setState(() {
      _failed = false;
      _playerState = 'loading';
    });
  }

  Widget _webView(String source) {
    const base = '$_appOrigin/trailer';
    final html = source.replaceAll(
      'VIDEO_ID_PLACEHOLDER',
      RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(widget.video) ? widget.video : '',
    );
    final url = WebUri(base);
    return InAppWebView(
      // Android loadDataWithBaseURL and WebView2's intercepted local page
      // let the iframe use the registered app identity as its HTTP Referer.
      initialData: Platform.isWindows
          ? null
          : InAppWebViewInitialData(data: html, baseUrl: url, historyUrl: url),
      initialUrlRequest: Platform.isWindows ? URLRequest(url: url) : null,
      initialSettings: InAppWebViewSettings(
        allowsInlineMediaPlayback: true,
        mediaPlaybackRequiresUserGesture: false,
        useShouldOverrideUrlLoading: true,
      ),
      shouldInterceptRequest: !Platform.isWindows
          ? null
          : (_, request) async {
              if (request.url.toString() != base) return null;
              return WebResourceResponse(
                statusCode: 200,
                reasonPhrase: 'OK',
                contentType: 'text/html; charset=utf-8',
                contentEncoding: '',
                data: utf8.encode(html),
              );
            },
      onWebViewCreated: (controller) {
        _controller = controller;
        controller.addJavaScriptHandler(
          handlerName: 'closeTrailer',
          callback: (_) {
            _close();
            return null;
          },
        );
        controller.addJavaScriptHandler(
          handlerName: 'trailerState',
          callback: (arguments) {
            if (mounted &&
                arguments.length == 1 &&
                const {
                  'ready',
                  'playing',
                  'paused',
                  'error',
                }.contains(arguments.first)) {
              final firstState = _playerState == 'loading';
              setState(() => _playerState = arguments.first as String);
              if (firstState &&
                  _toggleFocus.context != null &&
                  ModalRoute.of(context)?.isCurrent == true) {
                _toggleFocus.requestFocus();
              }
            }
            return null;
          },
        );
      },
      onLoadStop: (controller, _) async {
        await controller.evaluateJavascript(
          source:
              "window.addEventListener('keydown', e => { if(e.key === 'Escape') window.flutter_inappwebview.callHandler('closeTrailer'); });",
        );
      },
      onReceivedError: (_, request, error) {
        if (request.isForMainFrame == true) _fail();
      },
      shouldOverrideUrlLoading: (_, action) async {
        final target = action.request.url;
        if (action.isForMainFrame &&
            target?.host == 'www.youtube.com' &&
            target?.path == '/watch') {
          if (mounted) {
            await openExternalLink(context, ref, Uri.parse(target.toString()));
          }
          return NavigationActionPolicy.CANCEL;
        }
        return NavigationActionPolicy.ALLOW;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final available = ref.watch(trailerEmbedAvailableProvider);
    final page = ref.watch(_playerPageProvider);
    final watch = Uri.https('www.youtube.com', '/watch', {'v': widget.video});
    final tv = formFactorOf(context, ref).isTv;
    final embedded =
        available.asData?.value == true && !_failed && !page.hasError;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _close,
        const SingleActivator(LogicalKeyboardKey.goBack): _close,
        const SingleActivator(LogicalKeyboardKey.browserBack): _close,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: _close),
            title: Text('${widget.title} · Trailer'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: available.isLoading || (embedded && page.isLoading)
                        ? const CircularProgressIndicator()
                        : embedded
                        ? _webView(page.requireValue)
                        : SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (tv)
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: QrImageView(
                                      data: watch.toString(),
                                      backgroundColor: Colors.white,
                                      size: 180,
                                      semanticsLabel:
                                          'Open trailer on your phone',
                                    ),
                                  ),
                                Text(
                                  tv
                                      ? 'The trailer player could not open on this TV.'
                                      : 'Open this trailer on YouTube.',
                                ),
                                if (_failed ||
                                    isWebOsPlatform ||
                                    Platform.isAndroid)
                                  TextButton(
                                    onPressed: _retry,
                                    child: const Text('Retry'),
                                  ),
                              ],
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 12,
                    children: [
                      if (embedded && tv)
                        FilledButton.icon(
                          focusNode: _toggleFocus,
                          autofocus: true,
                          onPressed: () => _controller?.evaluateJavascript(
                            source: 'window.toggleTrailer?.()',
                          ),
                          icon: Icon(
                            _playerState == 'playing'
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          label: Text(
                            _playerState == 'playing'
                                ? 'Pause trailer'
                                : _playerState == 'error'
                                ? 'Retry'
                                : 'Play trailer',
                          ),
                        ),
                      OutlinedButton.icon(
                        autofocus: tv && !available.isLoading && !embedded,
                        onPressed: () => openExternalLink(context, ref, watch),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open in YouTube'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
