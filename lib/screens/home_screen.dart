import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/x_action.dart';
import '../main.dart';
import '../widgets/metric_card.dart';
import '../widgets/section_card.dart';
import '../widgets/charts/daily_line_chart.dart';
import '../widgets/charts/by_type_bar_chart.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final service = ref.watch(xActionsServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('X Engager'),
        elevation: 0,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<XAction>('actions').listenable(),
        builder: (context, Box<XAction> box, _) {
          final countsByType = service.countsByType();
          final dailyCounts = service.dailyCounts();
          final recentActions = service.getRecentActions(limit: 10);

          final totalPosts = countsByType[ActionType.post] ?? 0;
          final totalLikes = countsByType[ActionType.like] ?? 0;
          final totalRetweets = countsByType[ActionType.retweet] ?? 0;
          final totalReplies = countsByType[ActionType.reply] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metrics
                Text(
                  'Panoramica',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: (MediaQuery.of(context).size.width - 48) / 2,
                      child: MetricCard(
                        label: 'Post',
                        value: totalPosts.toString(),
                        icon: Icons.post_add,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(
                      width: (MediaQuery.of(context).size.width - 48) / 2,
                      child: MetricCard(
                        label: 'Like',
                        value: totalLikes.toString(),
                        icon: Icons.favorite,
                        color: Colors.red[400],
                      ),
                    ),
                    SizedBox(
                      width: (MediaQuery.of(context).size.width - 48) / 2,
                      child: MetricCard(
                        label: 'Retweet',
                        value: totalRetweets.toString(),
                        icon: Icons.repeat,
                        color: Colors.green[400],
                      ),
                    ),
                    SizedBox(
                      width: (MediaQuery.of(context).size.width - 48) / 2,
                      child: MetricCard(
                        label: 'Reply',
                        value: totalReplies.toString(),
                        icon: Icons.reply,
                        color: Colors.blue[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Daily chart
                SectionCard(
                  title: 'Attività ultimi 14 giorni',
                  child: DailyLineChart(dailyCounts: dailyCounts),
                ),
                const SizedBox(height: 16),

                // By type chart
                SectionCard(
                  title: 'Azioni per tipo',
                  child: ByTypeBarChart(countsByType: countsByType),
                ),
                const SizedBox(height: 16),

                // Recent actions
                SectionCard(
                  title: 'Azioni recenti',
                  padding: const EdgeInsets.all(0),
                  child: recentActions.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              'Nessuna azione ancora.\nCrea il tuo primo post!',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recentActions.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final action = recentActions[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    _getTypeColor(action.type, theme),
                                child: Icon(
                                  _getTypeIcon(action.type),
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                action.typeLabel,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (action.text != null)
                                    Text(
                                      action.text!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (action.tweetId != null)
                                    Text(
                                      'Tweet ID: ${action.tweetId}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  Text(
                                    DateFormat('dd/MM/yyyy HH:mm')
                                        .format(action.createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                              isThreeLine: action.text != null,
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getTypeIcon(ActionType type) {
    switch (type) {
      case ActionType.post:
        return Icons.post_add;
      case ActionType.like:
        return Icons.favorite;
      case ActionType.retweet:
        return Icons.repeat;
      case ActionType.reply:
        return Icons.reply;
      case ActionType.follow:
        return Icons.person_add;
    }
  }

  Color _getTypeColor(ActionType type, ThemeData theme) {
    switch (type) {
      case ActionType.post:
        return theme.colorScheme.primary;
      case ActionType.like:
        return Colors.red[400]!;
      case ActionType.retweet:
        return Colors.green[400]!;
      case ActionType.reply:
        return Colors.blue[400]!;
      case ActionType.follow:
        return Colors.orange[400]!;
    }
  }
}
