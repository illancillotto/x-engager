import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/x_action.dart';
import '../main.dart';

class LogScreen extends ConsumerStatefulWidget {
  const LogScreen({super.key});

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  ActionType? _filterType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = ref.watch(xActionsServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Azioni'),
        actions: [
          PopupMenuButton<ActionType?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtra per tipo',
            onSelected: (type) {
              setState(() => _filterType = type);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Tutte'),
              ),
              ...ActionType.values.map((type) {
                return PopupMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_getTypeIcon(type), size: 18),
                      const SizedBox(width: 8),
                      Text(_getTypeLabel(type)),
                    ],
                  ),
                );
              }),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Cancella tutto'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'clear') {
                _showClearDialog();
              }
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<XAction>('actions').listenable(),
        builder: (context, Box<XAction> box, _) {
          var actions = _filterType != null
              ? service.filterByType(_filterType!)
              : service.allSortedDesc();

          if (actions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _filterType != null
                        ? 'Nessuna azione di tipo ${_getTypeLabel(_filterType!)}'
                        : 'Nessuna azione registrata',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              if (_filterType != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: theme.colorScheme.primaryContainer,
                  child: Row(
                    children: [
                      Icon(
                        _getTypeIcon(_filterType!),
                        size: 18,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Filtrando: ${_getTypeLabel(_filterType!)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() => _filterType = null),
                        child: const Text('Rimuovi'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: actions.length,
                  itemBuilder: (context, index) {
                    final action = actions[index];
                    return Dismissible(
                      key: Key(action.key.toString()),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        service.deleteAction(action);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${action.typeLabel} eliminato'),
                            action: SnackBarAction(
                              label: 'Annulla',
                              onPressed: () {
                                // Note: In a production app, you'd implement undo functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Impossibile annullare (non implementato)'),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor: _getTypeColor(action.type, theme),
                            child: Icon(
                              _getTypeIcon(action.type),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                action.typeLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                DateFormat('HH:mm').format(action.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd/MM/yyyy')
                                    .format(action.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                              if (action.text != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  action.text!,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                              if (action.tweetId != null) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'ID: ${action.tweetId}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          isThreeLine:
                              action.text != null || action.tweetId != null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancella tutto'),
        content: const Text(
          'Sei sicuro di voler cancellare tutte le azioni? '
          'Questa operazione non può essere annullata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              final service = ref.read(xActionsServiceProvider);
              await service.clearAllActions();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tutte le azioni sono state cancellate'),
                  ),
                );
              }
            },
            child: const Text('Cancella', style: TextStyle(color: Colors.red)),
          ),
        ],
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
    }
  }

  String _getTypeLabel(ActionType type) {
    switch (type) {
      case ActionType.post:
        return 'Post';
      case ActionType.like:
        return 'Like';
      case ActionType.retweet:
        return 'Retweet';
      case ActionType.reply:
        return 'Reply';
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
    }
  }
}
