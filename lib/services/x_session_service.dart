import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:webview_flutter/webview_flutter.dart';

class XSessionService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  WebViewController? _controller;
  bool _isLoggedIn = false;

  static const String _cookiesKey = 'x_session_cookies';
  static const String _userHandleKey = 'x_user_handle';

  bool get isLoggedIn => _isLoggedIn;

  Future<void> init() async {
    // Check if we have saved session
    final savedCookies = await _secureStorage.read(key: _cookiesKey);
    _isLoggedIn = savedCookies != null && savedCookies.isNotEmpty;
  }

  Future<void> saveCookies(List<WebViewCookie> cookies) async {
    final cookieString = cookies
        .map((c) => '${c.name}=${c.value};domain=${c.domain};path=${c.path}')
        .join('||');
    await _secureStorage.write(key: _cookiesKey, value: cookieString);
    _isLoggedIn = true;
  }

  Future<List<WebViewCookie>?> loadCookies() async {
    final cookieString = await _secureStorage.read(key: _cookiesKey);
    if (cookieString == null || cookieString.isEmpty) return null;

    try {
      return cookieString.split('||').map((cookieStr) {
        final parts = cookieStr.split(';');
        final nameValue = parts[0].split('=');
        String domain = '.twitter.com';
        String path = '/';

        for (var part in parts.skip(1)) {
          if (part.startsWith('domain=')) {
            domain = part.substring(7);
          } else if (part.startsWith('path=')) {
            path = part.substring(5);
          }
        }

        return WebViewCookie(
          name: nameValue[0],
          value: nameValue.length > 1 ? nameValue[1] : '',
          domain: domain,
          path: path,
        );
      }).toList();
    } catch (e) {
      return null;
    }
  }

  Future<void> saveUserHandle(String handle) async {
    await _secureStorage.write(key: _userHandleKey, value: handle);
  }

  Future<String?> getUserHandle() async {
    return await _secureStorage.read(key: _userHandleKey);
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _cookiesKey);
    await _secureStorage.delete(key: _userHandleKey);
    _isLoggedIn = false;

    // Clear WebView cookies
    if (_controller != null) {
      final cookieManager = WebViewCookieManager();
      await cookieManager.clearCookies();
    }
  }

  void setController(WebViewController controller) {
    _controller = controller;
  }

  // JavaScript helpers for automation
  String getJsForLike(String tweetId) {
    return '''
      (function() {
        try {
          // Find the like button for this tweet
          const tweet = document.querySelector('[data-tweet-id="$tweetId"]');
          if (!tweet) return 'tweet_not_found';

          const likeButton = tweet.querySelector('[data-testid="like"]');
          if (!likeButton) return 'already_liked';

          likeButton.click();
          return 'success';
        } catch (e) {
          return 'error: ' + e.message;
        }
      })();
    ''';
  }

  String getJsForRetweet(String tweetId) {
    return '''
      (function() {
        try {
          const tweet = document.querySelector('[data-tweet-id="$tweetId"]');
          if (!tweet) return 'tweet_not_found';

          const retweetButton = tweet.querySelector('[data-testid="retweet"]');
          if (!retweetButton) return 'already_retweeted';

          retweetButton.click();

          // Wait for menu and click confirm
          setTimeout(() => {
            const confirmButton = document.querySelector('[data-testid="retweetConfirm"]');
            if (confirmButton) confirmButton.click();
          }, 500);

          return 'success';
        } catch (e) {
          return 'error: ' + e.message;
        }
      })();
    ''';
  }

  String getJsForFollow(String handle) {
    return '''
      (function() {
        try {
          const followButtons = document.querySelectorAll('[data-testid\$="-follow"]');
          for (let btn of followButtons) {
            if (btn.closest('[data-screen-name="$handle"]')) {
              btn.click();
              return 'success';
            }
          }
          return 'button_not_found';
        } catch (e) {
          return 'error: ' + e.message;
        }
      })();
    ''';
  }

  String getJsForCheckLogin() {
    return '''
      (function() {
        try {
          // Check if we're on a logged-in page
          const loggedInIndicators = [
            document.querySelector('[data-testid="SideNav_AccountSwitcher_Button"]'),
            document.querySelector('[data-testid="AppTabBar_Home_Link"]'),
            document.querySelector('a[href="/home"]')
          ];

          return loggedInIndicators.some(el => el !== null) ? 'logged_in' : 'not_logged_in';
        } catch (e) {
          return 'error: ' + e.message;
        }
      })();
    ''';
  }

  String getJsForGetUserHandle() {
    return '''
      (function() {
        try {
          const accountButton = document.querySelector('[data-testid="SideNav_AccountSwitcher_Button"]');
          if (!accountButton) return null;

          const handleElement = accountButton.querySelector('[dir="ltr"]');
          if (!handleElement) return null;

          return handleElement.textContent.trim();
        } catch (e) {
          return null;
        }
      })();
    ''';
  }

  // Execute automation action with error handling
  Future<Map<String, dynamic>> executeAction(
    String actionType,
    Map<String, String> params,
  ) async {
    if (_controller == null) {
      return {'success': false, 'error': 'WebView not initialized'};
    }

    try {
      String jsCode;
      switch (actionType) {
        case 'like':
          jsCode = getJsForLike(params['tweetId']!);
          break;
        case 'retweet':
          jsCode = getJsForRetweet(params['tweetId']!);
          break;
        case 'follow':
          jsCode = getJsForFollow(params['handle']!);
          break;
        default:
          return {'success': false, 'error': 'Unknown action type'};
      }

      final result = await _controller!.runJavaScriptReturningResult(jsCode);

      if (result.toString().contains('success')) {
        return {'success': true, 'result': result};
      } else {
        return {'success': false, 'error': result.toString()};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> checkLoginStatus() async {
    if (_controller == null) return false;

    try {
      final result = await _controller!.runJavaScriptReturningResult(
        getJsForCheckLogin(),
      );
      _isLoggedIn = result.toString().contains('logged_in');
      return _isLoggedIn;
    } catch (e) {
      return false;
    }
  }

  Future<String?> fetchUserHandle() async {
    if (_controller == null) return null;

    try {
      final result = await _controller!.runJavaScriptReturningResult(
        getJsForGetUserHandle(),
      );

      if (result.toString() != 'null') {
        final handle = result.toString().replaceAll('"', '');
        await saveUserHandle(handle);
        return handle;
      }
    } catch (e) {
      // Ignore errors
    }

    return null;
  }
}
