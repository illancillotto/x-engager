import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/x_action.dart';
import '../models/automation_config.dart';

class StorageService {
  static const String _actionsBoxName = 'actions';
  static const String _settingsBoxName = 'settings';
  static const String _automationConfigBoxName = 'automation_config';
  static const String _actionCountersBoxName = 'action_counters';

  Box<XAction>? _actionsBox;
  Box? _settingsBox;
  Box<AutomationConfig>? _automationConfigBox;
  Box<ActionCounter>? _actionCountersBox;

  Future<void> init() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocDir.path);

    // Register adapters
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ActionTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(XActionAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(AutomationConfigAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(TimeSlotAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(ActionCounterAdapter());
    }

    // Open boxes
    _actionsBox = await Hive.openBox<XAction>(_actionsBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _automationConfigBox = await Hive.openBox<AutomationConfig>(_automationConfigBoxName);
    _actionCountersBox = await Hive.openBox<ActionCounter>(_actionCountersBoxName);
  }

  Box<XAction> get actionsBox {
    if (_actionsBox == null || !_actionsBox!.isOpen) {
      throw Exception('Actions box not initialized');
    }
    return _actionsBox!;
  }

  Box get settingsBox {
    if (_settingsBox == null || !_settingsBox!.isOpen) {
      throw Exception('Settings box not initialized');
    }
    return _settingsBox!;
  }

  Box<AutomationConfig> get automationConfigBox {
    if (_automationConfigBox == null || !_automationConfigBox!.isOpen) {
      throw Exception('Automation config box not initialized');
    }
    return _automationConfigBox!;
  }

  Box<ActionCounter> get actionCountersBox {
    if (_actionCountersBox == null || !_actionCountersBox!.isOpen) {
      throw Exception('Action counters box not initialized');
    }
    return _actionCountersBox!;
  }

  // Settings helpers
  String? get apiKey => _settingsBox?.get('apiKey');
  set apiKey(String? value) => _settingsBox?.put('apiKey', value);

  String? get llmBaseUrl => _settingsBox?.get('llmBaseUrl');
  set llmBaseUrl(String? value) => _settingsBox?.put('llmBaseUrl', value);

  String? get model => _settingsBox?.get('model');
  set model(String? value) => _settingsBox?.put('model', value);

  String get defaultTone => _settingsBox?.get('defaultTone', defaultValue: 'ironico') ?? 'ironico';
  set defaultTone(String value) => _settingsBox?.put('defaultTone', value);

  int get defaultHashtags => _settingsBox?.get('defaultHashtags', defaultValue: 2) ?? 2;
  set defaultHashtags(int value) => _settingsBox?.put('defaultHashtags', value);

  Future<void> close() async {
    await _actionsBox?.close();
    await _settingsBox?.close();
    await _automationConfigBox?.close();
    await _actionCountersBox?.close();
  }
}
