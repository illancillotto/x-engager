import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../main.dart';
import 'x_login_screen.dart';

enum LLMProvider { openai, deepseek }

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _isObscured = true;
  bool _isTesting = false;
  LLMProvider _selectedProvider = LLMProvider.openai;

  final List<String> _tones = [
    'ironico',
    'professionale',
    'meme',
    'cortese',
    'entusiasta',
    'informativo',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _loadSettings() {
    final storage = ref.read(storageServiceProvider);
    _apiKeyController.text = storage.apiKey ?? '';

    // Determine provider from saved URL
    final savedUrl = storage.llmBaseUrl;
    if (savedUrl != null && savedUrl.contains('deepseek')) {
      _selectedProvider = LLMProvider.deepseek;
    } else {
      _selectedProvider = LLMProvider.openai;
    }

    setState(() {});
  }

  Future<void> _saveSettings() async {
    final storage = ref.read(storageServiceProvider);
    final llmService = ref.read(llmServiceProvider);

    // Save API key
    storage.apiKey = _apiKeyController.text.trim();

    // Configure LLM service based on provider
    String baseUrl;
    String model;

    switch (_selectedProvider) {
      case LLMProvider.openai:
        baseUrl = 'https://api.openai.com/v1/chat/completions';
        model = 'gpt-4o-mini';
        break;
      case LLMProvider.deepseek:
        baseUrl = 'https://api.deepseek.com/v1/chat/completions';
        model = 'deepseek-chat';
        break;
    }

    storage.llmBaseUrl = baseUrl;
    storage.model = model;

    // Update LLM service with new config
    llmService.setConfig(
      apiKey: storage.apiKey,
      baseUrl: baseUrl,
      model: model,
    );

    _showSnackBar('Impostazioni salvate con successo!');
  }

  Future<void> _testGeneration() async {
    if (_apiKeyController.text.trim().isEmpty) {
      _showSnackBar('Inserisci la API Key prima di testare', isError: true);
      return;
    }

    setState(() => _isTesting = true);

    try {
      // Temporarily configure the service for testing
      final llmService = ref.read(llmServiceProvider);

      String baseUrl;
      String model;

      switch (_selectedProvider) {
        case LLMProvider.openai:
          baseUrl = 'https://api.openai.com/v1/chat/completions';
          model = 'gpt-4o-mini';
          break;
        case LLMProvider.deepseek:
          baseUrl = 'https://api.deepseek.com/v1/chat/completions';
          model = 'deepseek-chat';
          break;
      }

      llmService.setConfig(
        apiKey: _apiKeyController.text.trim(),
        baseUrl: baseUrl,
        model: model,
      );

      final result = await llmService.testGeneration();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Test riuscito!'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'La connessione all\'API funziona correttamente.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Esempio di generazione:'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      result,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Errore: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isTesting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : null,
      ),
    );
  }

  Future<void> _handleLogin() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const XLoginScreen()),
    );

    if (result == true && mounted) {
      setState(() {});
      _showSnackBar('Login effettuato con successo!');
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Sei sicuro di voler disconnettere l\'account X?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final sessionService = ref.read(xSessionServiceProvider);
      await sessionService.logout();
      setState(() {});
      if (mounted) {
        _showSnackBar('Logout effettuato');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final storage = ref.watch(storageServiceProvider);
    final sessionService = ref.watch(xSessionServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // X Account Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.close,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Account X',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (sessionService.isLoggedIn) ...[
                    FutureBuilder<String?>(
                      future: sessionService.getUserHandle(),
                      builder: (context, snapshot) {
                        final handle = snapshot.data;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.green[100],
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.green[700],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Connesso',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (handle != null)
                                      Text(
                                        handle,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.green[900],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _handleLogout,
                            icon: const Icon(Icons.logout),
                            label: const Text('Logout'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange[700],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Non sei connesso a X',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _handleLogin,
                            icon: const Icon(Icons.login),
                            label: const Text('Connetti con X'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 20, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Connetti il tuo account per usare le funzioni di automazione',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Provider selection
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Provider LLM',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<LLMProvider>(
                    segments: const [
                      ButtonSegment(
                        value: LLMProvider.openai,
                        label: Text('OpenAI'),
                        icon: Icon(Icons.psychology),
                      ),
                      ButtonSegment(
                        value: LLMProvider.deepseek,
                        label: Text('DeepSeek'),
                        icon: Icon(Icons.hub),
                      ),
                    ],
                    selected: {_selectedProvider},
                    onSelectionChanged: (Set<LLMProvider> newSelection) {
                      setState(() => _selectedProvider = newSelection.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedProvider == LLMProvider.openai
                              ? 'OpenAI GPT-4o-mini'
                              : 'DeepSeek Chat',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedProvider == LLMProvider.openai
                              ? 'https://api.openai.com/v1/chat/completions'
                              : 'https://api.deepseek.com/v1/chat/completions',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // API Key
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'API Key',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _isObscured,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: 'sk-xxxx...',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.key),
                      suffixIcon: IconButton(
                        icon: Icon(_isObscured
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(() => _isObscured = !_isObscured);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveSettings,
                          icon: const Icon(Icons.save),
                          label: const Text('Salva'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isTesting ? null : _testGeneration,
                          icon: _isTesting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.science),
                          label: Text(_isTesting ? 'Test...' : 'Test API'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 20, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'La chiave API viene salvata localmente sul dispositivo',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Preferences
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preferenze',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: storage.defaultTone,
                    decoration: const InputDecoration(
                      labelText: 'Tono predefinito',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.mood),
                    ),
                    items: _tones.map((tone) {
                      return DropdownMenuItem(
                        value: tone,
                        child: Text(tone.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        storage.defaultTone = value;
                        _showSnackBar('Tono predefinito aggiornato');
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: storage.defaultHashtags,
                    decoration: const InputDecoration(
                      labelText: 'Hashtag predefiniti (max)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.tag),
                    ),
                    items: [0, 1, 2, 3, 4, 5].map((count) {
                      return DropdownMenuItem(
                        value: count,
                        child: Text(count.toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        storage.defaultHashtags = value;
                        _showSnackBar('Numero hashtag predefiniti aggiornato');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Info
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informazioni',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Versione'),
                    subtitle: const Text('1.0.0'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.code),
                    title: const Text('Framework'),
                    subtitle: const Text('Flutter + Riverpod'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.security),
                    title: const Text('Privacy'),
                    subtitle:
                        const Text('Tutti i dati sono salvati localmente'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
