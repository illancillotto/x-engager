import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../models/automation_config.dart';

class AutomationControlPanel extends ConsumerStatefulWidget {
  const AutomationControlPanel({super.key});

  @override
  ConsumerState<AutomationControlPanel> createState() =>
      _AutomationControlPanelState();
}

class _AutomationControlPanelState
    extends ConsumerState<AutomationControlPanel> {
  late AutomationConfig _config;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _loadStats();
  }

  void _loadConfig() {
    final automationService = ref.read(automationServiceProvider);
    setState(() {
      _config = automationService.config;
    });
  }

  void _loadStats() {
    final automationService = ref.read(automationServiceProvider);
    setState(() {
      _stats = automationService.getTodayStats();
    });
  }

  Future<void> _updateConfig() async {
    final automationService = ref.read(automationServiceProvider);
    await automationService.updateConfig(_config);
    _loadStats();
  }

  void _toggleAutomation(bool value) {
    setState(() {
      _config.enabled = value;
    });
    _updateConfig();
  }

  void _toggleActionType(String actionType, bool value) {
    setState(() {
      final types = List<String>.from(_config.enabledActionTypes);
      if (value && !types.contains(actionType)) {
        types.add(actionType);
      } else if (!value && types.contains(actionType)) {
        types.remove(actionType);
      }
      _config.enabledActionTypes = types;
    });
    _updateConfig();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLikeEnabled = _config.enabledActionTypes.contains('like');
    final isRetweetEnabled = _config.enabledActionTypes.contains('retweet');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.smart_toy_outlined,
                  size: 28,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Automazione',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Master switch
            Card(
              child: SwitchListTile(
                value: _config.enabled,
                onChanged: _toggleAutomation,
                title: const Text(
                  'Automazione attiva',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _config.enabled
                      ? 'Le azioni automatiche sono abilitate'
                      : 'Le azioni automatiche sono disabilitate',
                ),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _config.enabled
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _config.enabled ? Icons.play_arrow : Icons.stop,
                    color: _config.enabled ? Colors.green : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action types
            Text(
              'Tipi di azione',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    value: isLikeEnabled,
                    onChanged: _config.enabled
                        ? (value) => _toggleActionType('like', value)
                        : null,
                    title: const Text('Like automatici'),
                    subtitle: const Text('Metti like ai tweet nel feed'),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: Colors.red[400],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: isRetweetEnabled,
                    onChanged: _config.enabled
                        ? (value) => _toggleActionType('retweet', value)
                        : null,
                    title: const Text('Retweet automatici'),
                    subtitle: const Text('Retweet dei post nel feed'),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.repeat,
                        color: Colors.green[400],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Statistics
            if (_stats != null) ...[
              Text(
                'Statistiche di oggi',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatItem(
                              label: 'Azioni/ora',
                              value:
                                  '${_stats!['hourlyCount']}/${_stats!['hourlyLimit']}',
                              icon: Icons.access_time,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _StatItem(
                              label: 'Azioni/giorno',
                              value:
                                  '${_stats!['dailyCount']}/${_stats!['dailyLimit']}',
                              icon: Icons.calendar_today,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatItem(
                              label: 'In coda',
                              value: '${_stats!['queueSize']}',
                              icon: Icons.queue,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _StatItem(
                              label: 'Stato',
                              value: _stats!['canPerformAction']
                                  ? 'Pronto'
                                  : 'Limitato',
                              icon: _stats!['canPerformAction']
                                  ? Icons.check_circle
                                  : Icons.warning,
                              color: _stats!['canPerformAction']
                                  ? Colors.green
                                  : Colors.red,
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
