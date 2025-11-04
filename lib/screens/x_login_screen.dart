import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../main.dart';

class XLoginScreen extends ConsumerStatefulWidget {
  const XLoginScreen({super.key});

  @override
  ConsumerState<XLoginScreen> createState() => _XLoginScreenState();
}

class _XLoginScreenState extends ConsumerState<XLoginScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  String? _currentUrl;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final sessionService = ref.read(xSessionServiceProvider);

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
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });

            // Check if user is logged in
            final isLoggedIn = await sessionService.checkLoginStatus();
            if (isLoggedIn) {
              // Try to get user handle
              final handle = await sessionService.fetchUserHandle();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(handle != null
                      ? 'Logged in as $handle'
                      : 'Logged in successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://twitter.com/login'));

    // Set controller in session service
    sessionService.setController(_controller);
  }

  @override
  Widget build(BuildContext context) {
    final sessionService = ref.watch(xSessionServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login to X'),
        actions: [
          if (_currentUrl?.contains('home') == true)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => Navigator.pop(context, true),
              tooltip: 'Done',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (sessionService.isLoggedIn)
            Positioned(
              top: 16,
              right: 16,
              child: Chip(
                avatar: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                label: const Text('Logged In'),
                backgroundColor: Colors.green.withOpacity(0.2),
              ),
            ),
        ],
      ),
      floatingActionButton: sessionService.isLoggedIn
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.check),
              label: const Text('Continue'),
            )
          : null,
    );
  }
}
