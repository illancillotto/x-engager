import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/x_action.dart';

class XActionsService {
  final Box<XAction> _box;

  XActionsService(this._box);

  Future<void> postToX(String text) async {
    await _box.add(XAction(type: ActionType.post, text: text));
    await Share.share(text);
  }

  Future<void> likeTweet(String tweetId) async {
    await _box.add(XAction(type: ActionType.like, tweetId: tweetId));
    final uri = Uri.parse('https://twitter.com/intent/like?tweet_id=$tweetId');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> retweet(String tweetId) async {
    await _box.add(XAction(type: ActionType.retweet, tweetId: tweetId));
    final uri = Uri.parse('https://twitter.com/intent/retweet?tweet_id=$tweetId');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> replyToTweet(String tweetId, String replyText) async {
    await _box.add(
      XAction(type: ActionType.reply, tweetId: tweetId, text: replyText),
    );
    final uri = Uri.parse(
      'https://twitter.com/intent/tweet?in_reply_to=$tweetId&text=${Uri.encodeComponent(replyText)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> followUser(String handle) async {
    final uri = Uri.parse(
      'https://twitter.com/intent/follow?screen_name=$handle',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  List<XAction> allSortedDesc() {
    final actions = _box.values.toList();
    actions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return actions;
  }

  Map<ActionType, int> countsByType({DateTime? from}) {
    final counts = {for (var t in ActionType.values) t: 0};
    for (final action in _box.values) {
      if (from != null && action.createdAt.isBefore(from)) continue;
      counts[action.type] = (counts[action.type] ?? 0) + 1;
    }
    return counts;
  }

  Map<DateTime, int> dailyCounts({int days = 14}) {
    final start = DateTime.now().subtract(Duration(days: days - 1));
    final buckets = <DateTime, int>{};

    // Initialize buckets for each day
    for (int i = 0; i < days; i++) {
      final d = DateTime(start.year, start.month, start.day + i);
      buckets[d] = 0;
    }

    // Count actions per day
    for (final action in _box.values) {
      final d = DateTime(
        action.createdAt.year,
        action.createdAt.month,
        action.createdAt.day,
      );
      if (buckets.containsKey(d)) {
        buckets[d] = (buckets[d] ?? 0) + 1;
      }
    }

    return buckets;
  }

  int get totalCount => _box.length;

  List<XAction> getRecentActions({int limit = 20}) {
    final actions = allSortedDesc();
    return actions.take(limit).toList();
  }

  List<XAction> filterByType(ActionType type) {
    return _box.values.where((a) => a.type == type).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> deleteAction(XAction action) async {
    await action.delete();
  }

  Future<void> clearAllActions() async {
    await _box.clear();
  }
}
