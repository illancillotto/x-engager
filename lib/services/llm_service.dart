import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class LLMService {
  final Dio _dio = Dio();
  List<dynamic>? _templates;

  // Allow runtime override from settings
  String? _apiKeyOverride;
  String? _baseUrlOverride;
  String? _modelOverride;

  void setConfig({String? apiKey, String? baseUrl, String? model}) {
    _apiKeyOverride = apiKey;
    _baseUrlOverride = baseUrl;
    _modelOverride = model;
  }

  Future<void> _loadTemplates() async {
    if (_templates != null) return;
    try {
      final raw = await rootBundle.loadString('lib/data/prompts.json');
      _templates = json.decode(raw);
    } catch (e) {
      _templates = [];
      throw Exception('Failed to load prompts.json: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTemplates() async {
    await _loadTemplates();
    return _templates!.cast<Map<String, dynamic>>();
  }

  Future<String> generatePost({
    required String topic,
    required String tone,
    required String templateId,
  }) async {
    await _loadTemplates();

    // Get API configuration with priority: override > .env > defaults
    final apiKey = _apiKeyOverride ??
                   dotenv.env['OPENAI_API_KEY'] ??
                   '';

    if (apiKey.isEmpty) {
      throw Exception('API Key non configurata. Vai su Settings per impostarla.');
    }

    final model = _modelOverride ??
                  dotenv.env['MODEL'] ??
                  'gpt-4o-mini';

    final baseUrl = _baseUrlOverride ??
                    dotenv.env['LLM_BASE_URL'] ??
                    'https://api.openai.com/v1/chat/completions';

    // Find template
    final tpl = _templates!.firstWhere(
      (t) => t['id'] == templateId,
      orElse: () => _templates!.first,
    );

    final rules = tpl['rules'] ?? {};
    final maxChars = rules['max_chars'] ?? 220;
    final hashtagsMax = rules['hashtags_max'] ?? 2;
    final emojisMax = rules['emojis_max'] ?? 1;
    final parts = rules['parts'];

    String prompt;
    if (parts != null) {
      // Thread mode
      final partMaxChars = rules['part_max_chars'] ?? 230;
      prompt = """
Sei un copywriter italiano per X (Twitter).
- Tema: "$topic"
- Tono: $tone
- Crea un thread di $parts parti
- Ogni parte: max $partMaxChars caratteri
- Prima parte: hook accattivante
- Ultima parte: chiusura con domanda coinvolgente
- Hashtag: massimo $hashtagsMax totali
- Emoji: massimo $emojisMax per parte

Scrivi SOLO il testo del thread, una parte per riga, senza numeri o virgolette.
""";
    } else {
      // Single post mode
      prompt = """
Sei un copywriter italiano per X (Twitter).
- Tema: "$topic"
- Tono: $tone
- Limite: max $maxChars caratteri
- Hashtag: massimo $hashtagsMax
- Emoji: massimo $emojisMax
- Evita tag diretti non richiesti, niente spam
Scrivi SOLO il testo finale, senza virgolette.
""";
    }

    try {
      final response = await _dio.post(
        baseUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
        data: {
          "model": model,
          "messages": [
            {
              "role": "system",
              "content": "You write concise Italian posts for X (Twitter)."
            },
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.8,
          "max_tokens": parts != null ? 600 : 200,
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'API Error ${response.statusCode}: ${response.data}',
        );
      }

      String text = response.data['choices'][0]['message']['content'];
      text = text.trim();

      // Clean up common formatting issues
      text = text.replaceAll(RegExp(r'^["\047`]+|["\047`]+$'), '');
      text = text.replaceAll(RegExp(r'^\d+\.\s*'), '');

      return text;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'Errore API: ${e.response!.statusCode} - ${e.response!.data}',
        );
      } else {
        throw Exception('Errore di rete: ${e.message}');
      }
    } catch (e) {
      throw Exception('Errore generazione: $e');
    }
  }

  Future<String> testGeneration() async {
    return await generatePost(
      topic: 'Flutter development',
      tone: 'professionale',
      templateId: 'short_post',
    );
  }
}
