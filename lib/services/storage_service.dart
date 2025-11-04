import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/x_action.dart';

class StorageService {
  static const String _actionsBoxName = 'actions';
  static const String _settingsBoxName = 'settings';

  Box<XAction>? _actionsBox;
  Box? _settingsBox;

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

    // Open boxes
    _actionsBox = await Hive.openBox<XAction>(_actionsBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
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
  }
}
