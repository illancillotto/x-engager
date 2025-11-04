import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../widgets/prompt_selector.dart';

class ComposerScreen extends ConsumerStatefulWidget {
  const ComposerScreen({super.key});

  @override
  ConsumerState<ComposerScreen> createState() => _ComposerScreenState();
}

class _ComposerScreenState extends ConsumerState<ComposerScreen> {
  final _topicController = TextEditingController();
  final _textController = TextEditingController();
  final _tweetIdController = TextEditingController();

  String _selectedTone = 'ironico';
  String _selectedTemplateId = 'short_post';
  List<Map<String, dynamic>> _templates = [];
  bool _isGenerating = false;
  bool _showActions = false;

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
    _loadTemplates();
    _textController.addListener(() {
      setState(() {}); // Rebuild to update character count
    });
  }

  @override
  void dispose() {
    _topicController.dispose();
    _textController.dispose();
    _tweetIdController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    final llmService = ref.read(llmServiceProvider);
    final templates = await llmService.getTemplates();
    setState(() {
      _templates = templates;
    });
  }

  Future<void> _generatePost() async {
    if (_topicController.text.isEmpty) {
      _showSnackBar('Inserisci un tema per il post', isError: true);
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final llmService = ref.read(llmServiceProvider);
      final text = await llmService.generatePost(
        topic: _topicController.text,
        tone: _selectedTone,
        templateId: _selectedTemplateId,
      );

      setState(() {
        _textController.text = text;
        _showActions = true;
      });

      _showSnackBar('Post generato con successo!');
    } catch (e) {
      _showSnackBar('Errore: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _publishToX() async {
    if (_textController.text.isEmpty) {
      _showSnackBar('Il testo è vuoto', isError: true);
      return;
    }

    final length = _textController.text.length;
    if (length > 280) {
      _showSnackBar('Il testo supera i 280 caratteri ($length)', isError: true);
      return;
    }

    try {
      final service = ref.read(xActionsServiceProvider);
      await service.postToX(_textController.text);
      _showSnackBar('Apri l\'app X per pubblicare il post');
      _clearForm();
    } catch (e) {
      _showSnackBar('Errore: ${e.toString()}', isError: true);
    }
  }

  Future<void> _replyToTweet() async {
    if (_textController.text.isEmpty) {
      _showSnackBar('Il testo della risposta è vuoto', isError: true);
      return;
    }

    if (_tweetIdController.text.isEmpty) {
      _showSnackBar('Inserisci il Tweet ID', isError: true);
      return;
    }

    try {
      final service = ref.read(xActionsServiceProvider);
      await service.replyToTweet(_tweetIdController.text, _textController.text);
      _showSnackBar('Apri l\'app X per pubblicare la risposta');
      _clearForm();
    } catch (e) {
      _showSnackBar('Errore: ${e.toString()}', isError: true);
    }
  }

  Future<void> _retweet() async {
    if (_tweetIdController.text.isEmpty) {
      _showSnackBar('Inserisci il Tweet ID', isError: true);
      return;
    }

    try {
      final service = ref.read(xActionsServiceProvider);
      await service.retweet(_tweetIdController.text);
      _showSnackBar('Apri l\'app X per confermare il retweet');
      _tweetIdController.clear();
    } catch (e) {
      _showSnackBar('Errore: ${e.toString()}', isError: true);
    }
  }

  Future<void> _likeTweet() async {
    if (_tweetIdController.text.isEmpty) {
      _showSnackBar('Inserisci il Tweet ID', isError: true);
      return;
    }

    try {
      final service = ref.read(xActionsServiceProvider);
      await service.likeTweet(_tweetIdController.text);
      _showSnackBar('Apri l\'app X per confermare il like');
      _tweetIdController.clear();
    } catch (e) {
      _showSnackBar('Errore: ${e.toString()}', isError: true);
    }
  }

  void _clearForm() {
    _topicController.clear();
    _textController.clear();
    _tweetIdController.clear();
    setState(() => _showActions = false);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textLength = _textController.text.length;
    final isOverLimit = textLength > 280;
    final isWarning = textLength > 240;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Composer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'Pulisci',
            onPressed: _clearForm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Generation section
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
                      'Genera Post',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _topicController,
                      decoration: const InputDecoration(
                        labelText: 'Tema',
                        hintText: 'Es: Flutter development, AI trends, etc.',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.topic),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTone,
                      decoration: const InputDecoration(
                        labelText: 'Tono',
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
                          setState(() => _selectedTone = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_templates.isNotEmpty)
                      PromptSelector(
                        templates: _templates,
                        selectedTemplateId: _selectedTemplateId,
                        onChanged: (value) {
                          setState(() => _selectedTemplateId = value);
                        },
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isGenerating ? null : _generatePost,
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome),
                        label:
                            Text(_isGenerating ? 'Generazione...' : 'Genera'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Text editor
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Testo Post',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isOverLimit
                                ? Colors.red[100]
                                : isWarning
                                    ? Colors.orange[100]
                                    : theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$textLength/280',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isOverLimit
                                  ? Colors.red[900]
                                  : isWarning
                                      ? Colors.orange[900]
                                      : theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Scrivi o genera un post...',
                        border: const OutlineInputBorder(),
                        errorText: isOverLimit ? 'Testo troppo lungo!' : null,
                      ),
                      maxLines: 6,
                      onChanged: (value) {
                        setState(() => _showActions = value.isNotEmpty);
                      },
                    ),
                    if (isWarning && !isOverLimit)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Consiglio: mantieni il testo sotto i 240 caratteri',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if (_showActions) ...[
              const SizedBox(height: 16),
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
                        'Azioni',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _publishToX,
                          icon: const Icon(Icons.send),
                          label: const Text('Pubblica su X'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Altre azioni (richiede Tweet ID)',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _tweetIdController,
                        decoration: const InputDecoration(
                          labelText: 'Tweet ID',
                          hintText: 'Es: 1234567890',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.tag),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _replyToTweet,
                            icon: const Icon(Icons.reply, size: 18),
                            label: const Text('Reply'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _retweet,
                            icon: const Icon(Icons.repeat, size: 18),
                            label: const Text('Retweet'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[400],
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _likeTweet,
                            icon: const Icon(Icons.favorite, size: 18),
                            label: const Text('Like'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[400],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
