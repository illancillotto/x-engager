import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../main.dart';
import 'x_login_screen.dart';

class XFeedScreen extends ConsumerStatefulWidget {
  const XFeedScreen({super.key});

  @override
  ConsumerState<XFeedScreen> createState() => _XFeedScreenState();
}

class _XFeedScreenState extends ConsumerState<XFeedScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  String? _currentUrl;
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() async {
    final sessionService = ref.read(xSessionServiceProvider);

    // Check if logged in, otherwise redirect to login
    if (!sessionService.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const XLoginScreen()),
        );

        if (result != true && mounted) {
          Navigator.pop(context);
        } else if (mounted) {
          _initializeWebView();
        }
      });
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() => _isLoading = false);
            }
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
            _updateNavigationButtons();
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
            _updateNavigationButtons();

            // Load saved cookies if available
            final cookies = await sessionService.loadCookies();
            if (cookies != null) {
              final cookieManager = WebViewCookieManager();
              for (final cookie in cookies) {
                await cookieManager.setCookie(cookie);
              }
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://twitter.com/home'));

    sessionService.setController(_controller);
  }

  Future<void> _updateNavigationButtons() async {
    final canGoBack = await _controller.canGoBack();
    final canGoForward = await _controller.canGoForward();
    setState(() {
      _canGoBack = canGoBack;
      _canGoForward = canGoForward;
    });
  }

  Future<void> _goBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    }
  }

  Future<void> _goForward() async {
    if (await _controller.canGoForward()) {
      await _controller.goForward();
    }
  }

  void _showUrlDialog() {
    final urlController = TextEditingController(text: _currentUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vai a URL'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'URL',
            hintText: 'https://twitter.com/...',
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _controller.loadRequest(Uri.parse(value));
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                _controller.loadRequest(Uri.parse(url));
                Navigator.pop(context);
              }
            },
            child: const Text('Vai'),
          ),
        ],
      ),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                _controller.loadRequest(Uri.parse('https://twitter.com/home'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.explore),
              title: const Text('Esplora'),
              onTap: () {
                _controller.loadRequest(Uri.parse('https://twitter.com/explore'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifiche'),
              onTap: () {
                _controller.loadRequest(Uri.parse('https://twitter.com/notifications'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.mail),
              title: const Text('Messaggi'),
              onTap: () {
                _controller.loadRequest(Uri.parse('https://twitter.com/messages'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profilo'),
              onTap: () async {
                final sessionService = ref.read(xSessionServiceProvider);
                final handle = await sessionService.getUserHandle();
                if (handle != null) {
                  final cleanHandle = handle.replaceAll('@', '');
                  _controller.loadRequest(
                    Uri.parse('https://twitter.com/$cleanHandle'),
                  );
                }
                if (mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('X Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _canGoBack ? _goBack : null,
            tooltip: 'Indietro',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _canGoForward ? _goForward : null,
            tooltip: 'Avanti',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
            tooltip: 'Ricarica',
          ),
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: _showUrlDialog,
            tooltip: 'Vai a URL',
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: _showQuickActions,
            tooltip: 'Menu rapido',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: theme.scaffoldBackgroundColor,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Caricamento...'),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _controller.loadRequest(Uri.parse('https://twitter.com/compose/tweet'));
        },
        tooltip: 'Nuovo Tweet',
        child: const Icon(Icons.edit),
      ),
    );
  }
}
