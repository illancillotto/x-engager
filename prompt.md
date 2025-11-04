💡 Cursor Prompt — “X Engager Flutter (client-only)”

You are an expert Flutter engineer. Create a production-ready Flutter app named x_engager with the following requirements. Generate all files with complete code.

0) Project & Dependencies

Create a Flutter app:

Name: x_engager

Language: Dart

Platforms: Android (primary), iOS optional (don’t break iOS).

Add dependencies in pubspec.yaml:

flutter_riverpod, go_router, dio, flutter_dotenv

share_plus, url_launcher

hive, hive_flutter, path_provider, build_runner

fl_chart

Enable internet permission for Android (AndroidManifest):

<uses-permission android:name="android.permission.INTERNET" />

Create .env.example with:

OPENAI_API_KEY=sk-xxxx
LLM_BASE_URL=https://api.openai.com/v1/chat/completions
MODEL=gpt-4o-mini


Allow switching to DeepSeek by changing LLM_BASE_URL=https://api.deepseek.com/v1/chat/completions and MODEL=deepseek-chat.

Do not hardcode keys. Load at runtime via Settings screen and persist locally if user prefers.

Add .gitignore entries for .env, Hive boxes, build_runner outputs as usual.

1) App Architecture

Folders

lib/
  main.dart
  app_router.dart
  theme.dart
  screens/
    home_screen.dart
    composer_screen.dart
    log_screen.dart
    settings_screen.dart
  services/
    llm_service.dart
    x_actions_service.dart
    storage_service.dart
  models/
    x_action.dart
    x_action.g.dart     // build_runner
  data/
    prompts.json
  widgets/
    metric_card.dart
    section_card.dart
    charts/
      daily_line_chart.dart
      by_type_bar_chart.dart
    prompt_selector.dart


State management

Use flutter_riverpod providers for:

llmServiceProvider

xActionsServiceProvider

storageServiceProvider

settingsProvider (API key, model, base URL, tone default, hashtag defaults)

Navigation

Use go_router with bottom navigation (Home / Compose / Log / Settings).

2) Data Model (Hive)

models/x_action.dart

Enum ActionType { post, like, retweet, reply }

Class XAction (HiveType):

type (ActionType)

tweetId (String?)

text (String?)

createdAt (DateTime = now)

Generate adapters:

run: flutter packages pub run build_runner build --delete-conflicting-outputs

3) Services
3.1 LLM Service (client-only HTTP)

services/llm_service.dart

Uses dio to call ${LLM_BASE_URL} with headers Authorization: Bearer <OPENAI_API_KEY>.

Future<String> generatePost({required String topic, required String tone, required String templateId})

Load prompts.json, pick template rules (max chars, emojis, hashtags), craft a single system+user prompt in Italian.

Temperature default 0.8, max_tokens ~ 220.

Return clean text (strip quotes/markdown).

prompts.json include:

[
  {
    "id": "short_post",
    "description": "Post breve ironico/brillante",
    "rules": { "max_chars": 220, "hashtags_max": 2, "emojis_max": 1, "cta": "soft" }
  },
  {
    "id": "reply_helpful",
    "description": "Risposta utile e cortese",
    "rules": { "max_chars": 200, "avoid_tags": true }
  },
  {
    "id": "thread_3",
    "description": "Thread 3 parti, hook iniziale, chiusura con domanda",
    "rules": { "parts": 3, "part_max_chars": 230 }
  }
]

3.2 X Actions Service (Web Intents + Share) con logging

services/x_actions_service.dart

Depends on Hive Box<XAction>.

Methods (each crea un log prima di aprire l’intent):

postToX(String text) → Share.share(text)

likeTweet(String tweetId) → launch https://twitter.com/intent/like?tweet_id=$tweetId

retweet(String tweetId) → launch https://twitter.com/intent/retweet?tweet_id=$tweetId

replyToTweet(String tweetId, String replyText) → launch https://twitter.com/intent/tweet?in_reply_to=$tweetId&text=<encoded>

followUser(String handle) → launch https://twitter.com/intent/follow?screen_name=$handle

Helpers per dashboard:

List<XAction> allSortedDesc()

Map<ActionType,int> countsByType({DateTime? from})

Map<DateTime,int> dailyCounts({int days = 14})

3.3 Storage Service

services/storage_service.dart

Bootstrap Hive (init path, register adapters, open box actions).

Expose a singleton provider.

4) UI Screens
4.1 Home (dashboard moderno)

screens/home_screen.dart

Layout:

Metriche rapide (Wrap di MetricCard): Post / Like / Retweet / Reply

Grafico lineare ultimi 14 giorni: DailyLineChart(dailyCounts)

Grafico a barre per tipo: ByTypeBarChart(countsByType)

Cronologia: ListView con XAction (icone diverse per tipo, data, testo/ID)

Design:

Material 3, tema dark, colorSchemeSeed moderno (menta o azzurro)

Card arrotondate (r=18), ombre soft, spacing 16

ValueListenableBuilder su Hive box per aggiornamenti live.

4.2 Composer (generazione + publish)

screens/composer_screen.dart

Campi: Topic, Tone (dropdown: “ironico”, “professionale”, “meme”), Template (short_post/reply_helpful/thread_3)

Pulsante Genera → LLM

Editor testo (modificabile)

Pulsanti:

Pubblica su X (Share)

Reply (richiede Tweet ID + testo)

Retweet (Tweet ID)

Like (Tweet ID)

Mostra contatore caratteri live.

4.3 Log (cronologia estesa e filtri)

screens/log_screen.dart

Lista completa con filtri per tipo e data.

Esporta CSV locale (opzionale) – se semplice, ometti pure.

4.4 Settings

screens/settings_screen.dart

Input API Key (textfield + “Save locally”)

Switch provider:

OpenAI (predefinito): LLM_BASE_URL=https://api.openai.com/v1/chat/completions, MODEL=gpt-4o-mini

DeepSeek: https://api.deepseek.com/v1/chat/completions, MODEL=deepseek-chat

Test call button “Prova generazione 1 riga”

Preferenze: default tone, default hashtags

5) Widgets

widgets/metric_card.dart — label, value, icon

widgets/section_card.dart — contenitore ricorrente con titolo

widgets/prompt_selector.dart — dropdown caricato da prompts.json

Charts (fl_chart):

widgets/charts/daily_line_chart.dart — curved line, no grid, nice padding, bottom labels dd/MM

widgets/charts/by_type_bar_chart.dart — 4 barre (Post/Like/RT/Reply), no border/grid

6) main, theme, router

main.dart

WidgetsFlutterBinding.ensureInitialized();

Init dotenv (load .env if present)

Init Hive + register adapters + open box

Provide Riverpod ProviderScope

Set theme dark con colorSchemeSeed: Color(0xFF6EE7B7) (menta) e Material 3

Home: Scaffold con NavigationBar (Home / Compose / Log / Settings) usando go_router

app_router.dart

4 routes: /, /compose, /log, /settings

theme.dart

Dark theme, text styles puliti, radius 18 default (se utile usa ThemeData con useMaterial3: true)

7) UX & Edge cases

Validazione:

Tweet ID richiesto per Like/RT/Reply

Max 280 chars: mostra warning se oltre 240 (consigliato <= 240)

Error handling: snackbar su errori di rete LLM

Privacy: salva API key localmente (Hive secure box se vuoi, o plain box con disclaimer)

Rate self-control: non bloccare, ma mostra “Suggerimenti ritmo: max N azioni/ora”

8) Sample Code Stubs (include in files)
8.1 models/x_action.dart
import 'package:hive/hive.dart';
part 'x_action.g.dart';

@HiveType(typeId: 1)
enum ActionType {
  @HiveField(0) post,
  @HiveField(1) like,
  @HiveField(2) retweet,
  @HiveField(3) reply,
}

@HiveType(typeId: 2)
class XAction extends HiveObject {
  @HiveField(0) ActionType type;
  @HiveField(1) String? tweetId;
  @HiveField(2) String? text;
  @HiveField(3) DateTime createdAt;

  XAction({required this.type, this.tweetId, this.text, DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now();
}

8.2 services/x_actions_service.dart
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
    await _box.add(XAction(type: ActionType.reply, tweetId: tweetId, text: replyText));
    final uri = Uri.parse(
      'https://twitter.com/intent/tweet?in_reply_to=$tweetId&text=${Uri.encodeComponent(replyText)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  List<XAction> allSortedDesc() =>
      _box.values.toList()..sort((a,b)=>b.createdAt.compareTo(a.createdAt));

  Map<ActionType, int> countsByType({DateTime? from}) {
    final m = {for (var t in ActionType.values) t: 0};
    for (final a in _box.values) {
      if (from != null && a.createdAt.isBefore(from)) continue;
      m[a.type] = (m[a.type] ?? 0) + 1;
    }
    return m;
  }

  Map<DateTime, int> dailyCounts({int days = 14}) {
    final start = DateTime.now().subtract(Duration(days: days - 1));
    final buckets = <DateTime, int>{};
    for (int i=0; i<days; i++) {
      final d = DateTime(start.year, start.month, start.day + i);
      buckets[d] = 0;
    }
    for (final a in _box.values) {
      final d = DateTime(a.createdAt.year, a.createdAt.month, a.createdAt.day);
      if (buckets.containsKey(d)) buckets[d] = (buckets[d] ?? 0) + 1;
    }
    return buckets;
  }
}

8.3 services/llm_service.dart (OpenAI/DeepSeek switchable)
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class LLMService {
  final Dio _dio = Dio();
  List<dynamic>? _templates;

  Future<void> _loadTemplates() async {
    if (_templates != null) return;
    final raw = await rootBundle.loadString('lib/data/prompts.json');
    _templates = json.decode(raw);
  }

  Future<String> generatePost({
    required String topic,
    required String tone,
    required String templateId,
  }) async {
    await _loadTemplates();
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    final model = dotenv.env['MODEL'] ?? 'gpt-4o-mini';
    final baseUrl = dotenv.env['LLM_BASE_URL'] ??
        'https://api.openai.com/v1/chat/completions';

    final tpl = _templates!.firstWhere((t) => t['id'] == templateId, orElse: ()=>_templates!.first);
    final rules = tpl['rules'] ?? {};
    final maxChars = rules['max_chars'] ?? 220;
    final hashtagsMax = rules['hashtags_max'] ?? 2;
    final emojisMax = rules['emojis_max'] ?? 1;

    final prompt = """
Sei un copywriter italiano per X (Twitter).
- Tema: "$topic"
- Tono: $tone
- Limite: max $maxChars caratteri
- Hashtag: massimo $hashtagsMax
- Emoji: massimo $emojisMax
- Evita tag diretti non richiesti, niente spam
Scrivi SOLO il testo finale, senza virgolette.
""";

    final response = await _dio.post(
      baseUrl,
      options: Options(headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      }),
      data: {
        "model": model,
        "messages": [
          {"role": "system", "content": "You write concise Italian posts for X."},
          {"role": "user", "content": prompt}
        ],
        "temperature": 0.8,
        "max_tokens": 200
      },
    );

    String text = response.data['choices'][0]['message']['content'];
    return text.trim();
  }
}

9) Finishing touches

Bottom bar + router: linka Home/Compose/Log/Settings.

Home usa i widget chart personalizzati.

Settings salva/legge API key e LLM endpoint in Hive o dotenv runtime override.

Mostra snackbar su errori rete / validazioni mancanti.

Build Runner

flutter packages pub run build_runner build --delete-conflicting-outputs


Run

flutter run


That’s it. Generate all files and ensure the app builds and runs on Android.