import 'package:hive/hive.dart';

part 'x_action.g.dart';

@HiveType(typeId: 1)
enum ActionType {
  @HiveField(0)
  post,
  @HiveField(1)
  like,
  @HiveField(2)
  retweet,
  @HiveField(3)
  reply,
}

@HiveType(typeId: 2)
class XAction extends HiveObject {
  @HiveField(0)
  ActionType type;

  @HiveField(1)
  String? tweetId;

  @HiveField(2)
  String? text;

  @HiveField(3)
  DateTime createdAt;

  XAction({
    required this.type,
    this.tweetId,
    this.text,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get typeLabel {
    switch (type) {
      case ActionType.post:
        return 'Post';
      case ActionType.like:
        return 'Like';
      case ActionType.retweet:
        return 'Retweet';
      case ActionType.reply:
        return 'Reply';
    }
  }
}
