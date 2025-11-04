import 'package:hive/hive.dart';

part 'automation_config.g.dart';

@HiveType(typeId: 3)
class AutomationConfig extends HiveObject {
  @HiveField(0)
  bool enabled;

  @HiveField(1)
  List<TimeSlot> timeSlots;

  @HiveField(2)
  int maxActionsPerHour;

  @HiveField(3)
  int maxActionsPerDay;

  @HiveField(4)
  int minDelaySeconds;

  @HiveField(5)
  int maxDelaySeconds;

  @HiveField(6)
  List<String> enabledActionTypes; // 'like', 'retweet', 'reply', 'post'

  @HiveField(7)
  bool randomizeDelay;

  @HiveField(8)
  bool respectRateLimits;

  AutomationConfig({
    this.enabled = false,
    this.timeSlots = const [],
    this.maxActionsPerHour = 10,
    this.maxActionsPerDay = 50,
    this.minDelaySeconds = 30,
    this.maxDelaySeconds = 90,
    this.enabledActionTypes = const ['like', 'retweet'],
    this.randomizeDelay = true,
    this.respectRateLimits = true,
  });

  bool isActionEnabled(String actionType) {
    return enabledActionTypes.contains(actionType);
  }

  bool isWithinTimeSlots(DateTime dateTime) {
    if (timeSlots.isEmpty) return true; // No restrictions

    final time = TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    return timeSlots.any((slot) => slot.contains(time));
  }

  Duration getRandomDelay() {
    if (!randomizeDelay) {
      return Duration(seconds: minDelaySeconds);
    }

    final random = DateTime.now().millisecondsSinceEpoch %
                   (maxDelaySeconds - minDelaySeconds);
    return Duration(seconds: minDelaySeconds + random);
  }
}

@HiveType(typeId: 4)
class TimeSlot extends HiveObject {
  @HiveField(0)
  int startHour;

  @HiveField(1)
  int startMinute;

  @HiveField(2)
  int endHour;

  @HiveField(3)
  int endMinute;

  TimeSlot({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  bool contains(TimeOfDay time) {
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;
    final currentMinutes = time.hour * 60 + time.minute;

    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  @override
  String toString() {
    return '${_formatTime(startHour, startMinute)} - ${_formatTime(endHour, endMinute)}';
  }

  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

class TimeOfDay {
  final int hour;
  final int minute;

  TimeOfDay({required this.hour, required this.minute});
}

@HiveType(typeId: 5)
class ActionCounter extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  int hourlyCount;

  @HiveField(2)
  int dailyCount;

  @HiveField(3)
  DateTime lastActionTime;

  ActionCounter({
    required this.date,
    this.hourlyCount = 0,
    this.dailyCount = 0,
    DateTime? lastActionTime,
  }) : lastActionTime = lastActionTime ?? DateTime.now();

  bool canPerformAction(AutomationConfig config) {
    final now = DateTime.now();

    // Reset counters if it's a new hour
    if (now.hour != lastActionTime.hour) {
      hourlyCount = 0;
    }

    // Reset counters if it's a new day
    if (now.day != lastActionTime.day) {
      hourlyCount = 0;
      dailyCount = 0;
    }

    return hourlyCount < config.maxActionsPerHour &&
           dailyCount < config.maxActionsPerDay;
  }

  void incrementCounters() {
    hourlyCount++;
    dailyCount++;
    lastActionTime = DateTime.now();
  }
}
