import 'dart:async';
import 'dart:math';
import 'package:hive/hive.dart';
import '../models/automation_config.dart';
import '../models/x_action.dart';
import 'x_session_service.dart';

class AutomationService {
  final XSessionService _sessionService;
  final Box<AutomationConfig> _configBox;
  final Box<ActionCounter> _counterBox;
  final Box<XAction> _actionsBox;

  Timer? _schedulerTimer;
  final List<ScheduledAction> _queue = [];
  bool _isProcessing = false;

  AutomationService(
    this._sessionService,
    this._configBox,
    this._counterBox,
    this._actionsBox,
  );

  AutomationConfig get config {
    var cfg = _configBox.get('config');
    if (cfg == null) {
      cfg = AutomationConfig();
      _configBox.put('config', cfg);
    }
    return cfg;
  }

  ActionCounter get counter {
    final now = DateTime.now();
    final key = '${now.year}-${now.month}-${now.day}';
    var counter = _counterBox.get(key);
    if (counter == null) {
      counter = ActionCounter(date: now);
      _counterBox.put(key, counter);
    }
    return counter;
  }

  Future<void> init() async {
    // Start the scheduler loop
    _schedulerTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _processQueue(),
    );
  }

  void dispose() {
    _schedulerTimer?.cancel();
  }

  // Schedule an action for automation
  Future<bool> scheduleAction(ScheduledAction action) async {
    if (!config.enabled) {
      return false;
    }

    if (!config.isActionEnabled(action.type)) {
      return false;
    }

    if (!_canPerformAction()) {
      return false;
    }

    _queue.add(action);
    return true;
  }

  // Check if we can perform an action now
  bool _canPerformAction() {
    final now = DateTime.now();

    // Check if within time slots
    if (!config.isWithinTimeSlots(now)) {
      return false;
    }

    // Check rate limits
    final actionCounter = counter;
    if (!actionCounter.canPerformAction(config)) {
      return false;
    }

    return true;
  }

  // Process the queue of scheduled actions
  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;
    if (!_sessionService.isLoggedIn) return;

    _isProcessing = true;

    try {
      while (_queue.isNotEmpty && _canPerformAction()) {
        final action = _queue.removeAt(0);

        // Wait for random delay
        final delay = config.getRandomDelay();
        await Future.delayed(delay);

        // Execute the action
        final result = await _executeScheduledAction(action);

        if (result) {
          // Update counters
          final actionCounter = counter;
          actionCounter.incrementCounters();
          await actionCounter.save();

          // Log the action
          await _logAction(action);
        }

        // Add some extra random delay between actions
        await Future.delayed(Duration(
          seconds: 1 + Random().nextInt(3),
        ));
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<bool> _executeScheduledAction(ScheduledAction action) async {
    try {
      final result = await _sessionService.executeAction(
        action.type,
        action.params,
      );
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _logAction(ScheduledAction action) async {
    final xAction = XAction(
      type: _mapActionType(action.type),
      text: action.params['text'],
      tweetId: action.params['tweetId'],
    );
    await _actionsBox.add(xAction);
  }

  ActionType _mapActionType(String type) {
    switch (type) {
      case 'like':
        return ActionType.like;
      case 'retweet':
        return ActionType.retweet;
      case 'reply':
        return ActionType.reply;
      case 'post':
        return ActionType.post;
      case 'follow':
        return ActionType.follow;
      default:
        return ActionType.post;
    }
  }

  // Update automation config
  Future<void> updateConfig(AutomationConfig newConfig) async {
    await _configBox.put('config', newConfig);
  }

  // Get stats for today
  Map<String, dynamic> getTodayStats() {
    final actionCounter = counter;
    return {
      'hourlyCount': actionCounter.hourlyCount,
      'dailyCount': actionCounter.dailyCount,
      'hourlyLimit': config.maxActionsPerHour,
      'dailyLimit': config.maxActionsPerDay,
      'hourlyRemaining': config.maxActionsPerHour - actionCounter.hourlyCount,
      'dailyRemaining': config.maxActionsPerDay - actionCounter.dailyCount,
      'canPerformAction': _canPerformAction(),
      'queueSize': _queue.length,
    };
  }

  // Clear the queue
  void clearQueue() {
    _queue.clear();
  }

  // Get queue size
  int get queueSize => _queue.length;

  // Manually trigger an action (bypasses scheduling but respects limits)
  Future<Map<String, dynamic>> executeManualAction(
    String actionType,
    Map<String, String> params,
  ) async {
    if (!_canPerformAction()) {
      return {
        'success': false,
        'error': 'Rate limit exceeded or outside time slots',
      };
    }

    final result = await _sessionService.executeAction(actionType, params);

    if (result['success'] == true) {
      // Update counters
      final actionCounter = counter;
      actionCounter.incrementCounters();
      await actionCounter.save();

      // Log the action
      await _logAction(ScheduledAction(
        type: actionType,
        params: params,
      ));
    }

    return result;
  }

  // Batch schedule multiple actions
  Future<int> scheduleMultipleActions(List<ScheduledAction> actions) async {
    int scheduled = 0;
    for (final action in actions) {
      if (await scheduleAction(action)) {
        scheduled++;
      }
    }
    return scheduled;
  }
}

class ScheduledAction {
  final String type; // 'like', 'retweet', 'reply', 'post', 'follow'
  final Map<String, String> params;
  final DateTime scheduledAt;

  ScheduledAction({
    required this.type,
    required this.params,
    DateTime? scheduledAt,
  }) : scheduledAt = scheduledAt ?? DateTime.now();
}
