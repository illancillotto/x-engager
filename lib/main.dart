import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/storage_service.dart';
import 'services/llm_service.dart';
import 'services/x_actions_service.dart';
import 'services/x_session_service.dart';
import 'services/automation_service.dart';
import 'app_router.dart';
import 'theme.dart';

// Global providers
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('storageServiceProvider must be overridden');
});

final llmServiceProvider = Provider<LLMService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final llmService = LLMService();

  // Configure with saved settings
  llmService.setConfig(
    apiKey: storage.apiKey,
    baseUrl: storage.llmBaseUrl,
    model: storage.model,
  );

  return llmService;
});

final xActionsServiceProvider = Provider<XActionsService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return XActionsService(storage.actionsBox);
});

final xSessionServiceProvider = Provider<XSessionService>((ref) {
  throw UnimplementedError('xSessionServiceProvider must be overridden');
});

final automationServiceProvider = Provider<AutomationService>((ref) {
  throw UnimplementedError('automationServiceProvider must be overridden');
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (optional, will fail gracefully if .env doesn't exist)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('No .env file found, continuing without it...');
  }

  // Initialize Hive
  final storageService = StorageService();
  await storageService.init();

  // Initialize X session service
  final xSessionService = XSessionService();
  await xSessionService.init();

  // Initialize automation service
  final automationService = AutomationService(
    xSessionService,
    storageService.automationConfigBox,
    storageService.actionCountersBox,
    storageService.actionsBox,
  );
  await automationService.init();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
        xSessionServiceProvider.overrideWithValue(xSessionService),
        automationServiceProvider.overrideWithValue(automationService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'X Engager',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default to dark mode
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
