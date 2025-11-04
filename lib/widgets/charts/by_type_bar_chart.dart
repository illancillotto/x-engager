import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/x_action.dart';

class ByTypeBarChart extends StatelessWidget {
  final Map<ActionType, int> countsByType;

  const ByTypeBarChart({
    super.key,
    required this.countsByType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final maxY = countsByType.values.isEmpty
        ? 10.0
        : countsByType.values.reduce((a, b) => a > b ? a : b).toDouble() * 1.2;

    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final type = ActionType.values[group.x.toInt()];
                  return BarTooltipItem(
                    '${_getTypeLabel(type)}\n${rod.toY.toInt()}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.max || value == meta.min) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= ActionType.values.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _getTypeShortLabel(ActionType.values[index]),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            barGroups: ActionType.values.asMap().entries.map((entry) {
              final index = entry.key;
              final type = entry.value;
              final count = countsByType[type] ?? 0;

              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: count.toDouble(),
                    color: _getTypeColor(type, theme),
                    width: 32,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
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
      case ActionType.follow:
        return 'Follow';
    }
  }

  String _getTypeShortLabel(ActionType type) {
    switch (type) {
      case ActionType.post:
        return 'Post';
      case ActionType.like:
        return 'Like';
      case ActionType.retweet:
        return 'RT';
      case ActionType.reply:
        return 'Reply';
      case ActionType.follow:
        return 'Follow';
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
